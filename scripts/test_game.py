# test_game.py

#!/usr/bin/env python3
"""
FPGA Game UART Test Script with START button support
Tests Space Invaders game by sending control packets via serial

Usage:
    python test_game_with_start.py --port COM4        # Windows
    python test_game_with_start.py --port /dev/ttyUSB0  # Linux
    python test_game_with_start.py --port /dev/cu.usbserial  # macOS
"""

import serial
import time
import argparse
import sys
from dataclasses import dataclass

# ANSI color codes for pretty output
class Color:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'
    MAGENTA = '\033[95m'

@dataclass
class GamePacket:
    """8-byte packet structure for FPGA game"""
    packet_type: int  # Byte 0: 0x01=player, 0x03=enemy
    direction: int    # Byte 1: 0x00=none, 0x01=up, 0x02=down, 0x03=left, 0x04=right, 0x09=START
    action: int       # Byte 2: 0x01=fire, 0x00=no action
    
    def to_bytes(self):
        """Convert packet to 8-byte array"""
        return bytes([
            self.packet_type,
            self.direction,
            self.action,
            0x00, 0x00, 0x00, 0x00, 0x00  # Padding to 8 bytes
        ])
    
    def __str__(self):
        dir_map = {0: "NONE", 1: "UP", 2: "DOWN", 3: "LEFT", 4: "RIGHT", 9: "START"}
        act_map = {0: "---", 1: "FIRE!"}
        return f"Type:0x{self.packet_type:02X} Dir:{dir_map.get(self.direction, 'UNK')} Action:{act_map.get(self.action, 'UNK')}"


class FPGAGameTester:
    def __init__(self, port, baudrate=115200):
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        
    def connect(self):
        """Open serial connection"""
        try:
            self.ser = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=1
            )
            print(f"{Color.GREEN}✓ Connected to {self.port} at {self.baudrate} baud{Color.RESET}")
            time.sleep(0.5)  # Wait for connection to stabilize
            return True
        except serial.SerialException as e:
            print(f"{Color.RED}✗ Failed to open {self.port}: {e}{Color.RESET}")
            return False
    
    def disconnect(self):
        """Close serial connection"""
        if self.ser and self.ser.is_open:
            self.ser.close()
            print(f"{Color.YELLOW}Connection closed{Color.RESET}")
    
    def send_packet(self, packet: GamePacket, delay=0.1):
        """Send a single packet to FPGA"""
        if not self.ser or not self.ser.is_open:
            print(f"{Color.RED}✗ Serial port not open{Color.RESET}")
            return False
        
        data = packet.to_bytes()
        self.ser.write(data)
        self.ser.flush()
        
        # Display sent packet
        hex_str = ' '.join(f'{b:02X}' for b in data)
        print(f"{Color.CYAN}→ Sent: {Color.RESET}{hex_str} {Color.BLUE}({packet}){Color.RESET}")
        
        time.sleep(delay)
        return True
    
    def send_start_button(self):
        """Send START button press (direction=0x09)"""
        print(f"\n{Color.MAGENTA}{'*'*60}{Color.RESET}")
        print(f"{Color.MAGENTA}★ Pressing START Button (OPTIONS mapped to 0x09){Color.RESET}")
        print(f"{Color.MAGENTA}{'*'*60}{Color.RESET}")
        
        # Send START command
        packet = GamePacket(packet_type=0x01, direction=0x09, action=0x00)
        self.send_packet(packet, delay=0.2)
        
        # Release (return to direction=0x00)
        packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
        self.send_packet(packet, delay=0.5)
        
        print(f"{Color.GREEN}✓ START button pressed{Color.RESET}")
        print(f"{Color.GREEN}✓ Game should transition from IDLE → PLAYING state{Color.RESET}")
        print(f"{Color.GREEN}✓ Enemies should start moving{Color.RESET}")
    
    def test_explicit_start(self):
        """Test 0: Explicit START button press"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 0: Explicit Game Start with START Button{Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        print("This test sends the START command (direction=0x09) to begin the game.")
        print("This simulates pressing the OPTIONS button on PS5 controller.\n")
        
        self.send_start_button()
        time.sleep(1.5)
    
    def test_auto_start(self):
        """Test 1: Auto-start game with any input (fallback)"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 1: Auto-Start Game (Fallback){Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        print("Sending any player input can also start the game if not already started...")
        
        # Send a simple movement packet (should trigger auto-start if needed)
        packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
        self.send_packet(packet, delay=0.5)
        
        print(f"{Color.GREEN}✓ Fallback auto-start signal sent{Color.RESET}")
        time.sleep(1)
    
    def test_movement(self):
        """Test 2: Player movement"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 2: Player Movement{Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        
        movements = [
            ("Move LEFT", 0x03),
            ("Move LEFT (hold)", 0x03),
            ("Move RIGHT", 0x04),
            ("Move RIGHT (hold)", 0x04),
            ("Move LEFT again", 0x03),
            ("STOP", 0x00),
        ]
        
        for desc, direction in movements:
            print(f"\n{Color.YELLOW}{desc}{Color.RESET}")
            packet = GamePacket(packet_type=0x01, direction=direction, action=0x00)
            self.send_packet(packet, delay=0.3)
        
        print(f"\n{Color.GREEN}✓ Movement test complete{Color.RESET}")
    
    def test_firing(self):
        """Test 3: Firing projectiles"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 3: Firing Projectiles{Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        
        print(f"\n{Color.YELLOW}Fire 5 shots with 0.5s delay{Color.RESET}")
        for i in range(5):
            print(f"\n  Shot {i+1}/5:")
            # Fire packet
            packet = GamePacket(packet_type=0x01, direction=0x00, action=0x01)
            self.send_packet(packet, delay=0.1)
            
            # Release (action=0x00) to allow next shot
            packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
            self.send_packet(packet, delay=0.4)
        
        print(f"\n{Color.GREEN}✓ Firing test complete{Color.RESET}")
        print(f"{Color.GREEN}✓ You should see white projectiles moving upward{Color.RESET}")
    
    def test_move_and_fire(self):
        """Test 4: Combined movement and firing"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 4: Move & Fire Combo{Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        
        actions = [
            ("Move left + FIRE", 0x03, 0x01),
            ("Keep moving left", 0x03, 0x00),
            ("Move right + FIRE", 0x04, 0x01),
            ("Keep moving right", 0x04, 0x00),
            ("Center + FIRE", 0x00, 0x01),
            ("Stop", 0x00, 0x00),
        ]
        
        for desc, direction, action in actions:
            print(f"\n{Color.YELLOW}{desc}{Color.RESET}")
            packet = GamePacket(packet_type=0x01, direction=direction, action=action)
            self.send_packet(packet, delay=0.4)
        
        print(f"\n{Color.GREEN}✓ Combined test complete{Color.RESET}")
    
    def test_rapid_fire(self):
        """Test 5: Rapid fire sequence"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 5: Rapid Fire (Stress Test){Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.YELLOW}Sending 10 rapid fire commands...{Color.RESET}")
        
        for i in range(10):
            # Fire
            packet = GamePacket(packet_type=0x01, direction=0x00, action=0x01)
            self.send_packet(packet, delay=0.05)
            
            # Release
            packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
            self.send_packet(packet, delay=0.05)
        
        print(f"\n{Color.GREEN}✓ Rapid fire test complete{Color.RESET}")
        print(f"{Color.YELLOW}⚠ Note: Game may only fire one projectile at a time{Color.RESET}")
    
    def test_restart_game(self):
        """Test 6: Restart game after completion"""
        print(f"\n{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}TEST 6: Game Restart{Color.RESET}")
        print(f"{Color.BOLD}{'='*60}{Color.RESET}")
        print(f"{Color.YELLOW}Pressing START again to restart/return to menu...{Color.RESET}")
        
        self.send_start_button()
        
        print(f"\n{Color.GREEN}✓ Restart command sent{Color.RESET}")
        print(f"{Color.GREEN}✓ Game should reset or return to menu{Color.RESET}")
    
    def run_all_tests(self):
        """Run complete test suite"""
        print(f"\n{Color.BOLD}{Color.GREEN}{'='*60}{Color.RESET}")
        print(f"{Color.BOLD}{Color.GREEN}FPGA SPACE INVADERS - UART TEST SUITE{Color.RESET}")
        print(f"{Color.BOLD}{Color.GREEN}(With START Button Support){Color.RESET}")
        print(f"{Color.BOLD}{Color.GREEN}{'='*60}{Color.RESET}")
        
        if not self.connect():
            return
        
        try:
            # TEST 0: Explicit START button
            self.test_explicit_start()
            time.sleep(2)
            
            # TEST 1: Auto-start fallback
            self.test_auto_start()
            time.sleep(1)
            
            # TEST 2: Movement
            self.test_movement()
            time.sleep(1)
            
            # TEST 3: Firing
            self.test_firing()
            time.sleep(1)
            
            # TEST 4: Combined actions
            self.test_move_and_fire()
            time.sleep(1)
            
            # TEST 5: Rapid fire
            self.test_rapid_fire()
            time.sleep(1)
            
            # TEST 6: Restart
            self.test_restart_game()
            
            # Final summary
            print(f"\n{Color.BOLD}{Color.GREEN}{'='*60}{Color.RESET}")
            print(f"{Color.BOLD}{Color.GREEN}✓ ALL TESTS COMPLETED{Color.RESET}")
            print(f"{Color.BOLD}{Color.GREEN}{'='*60}{Color.RESET}")
            print(f"\n{Color.CYAN}What to check on VGA display:{Color.RESET}")
            print(f"  • Game starts when START (0x09) is sent")
            print(f"  • Green square (player) at bottom")
            print(f"  • Player moves left/right smoothly")
            print(f"  • White projectiles fire upward")
            print(f"  • Red enemy grid moving")
            print(f"  • Enemies disappear when hit")
            print(f"  • START button returns to menu/restarts")
            print(f"  • LEDs show game state\n")
            
            print(f"{Color.MAGENTA}PS5 Controller Mapping:{Color.RESET}")
            print(f"  • Left Stick / D-Pad → Move player")
            print(f"  • X Button → Fire")
            print(f"  • OPTIONS Button → Start/Restart (direction=0x09)")
            print()
            
        except KeyboardInterrupt:
            print(f"\n{Color.YELLOW}Test interrupted by user{Color.RESET}")
        finally:
            self.disconnect()


def interactive_mode(tester):
    """Interactive control mode"""
    print(f"\n{Color.BOLD}{Color.CYAN}{'='*60}{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}INTERACTIVE CONTROL MODE{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}{'='*60}{Color.RESET}")
    print(f"\nControls:")
    print(f"  {Color.GREEN}a{Color.RESET} - Move LEFT")
    print(f"  {Color.GREEN}d{Color.RESET} - Move RIGHT")
    print(f"  {Color.GREEN}SPACE{Color.RESET} - FIRE")
    print(f"  {Color.GREEN}s{Color.RESET} - STOP")
    print(f"  {Color.MAGENTA}ENTER{Color.RESET} - START button (begin/restart game)")
    print(f"  {Color.GREEN}q{Color.RESET} - Quit\n")
    
    if not tester.connect():
        return
    
    try:
        while True:
            cmd = input(f"{Color.YELLOW}Command > {Color.RESET}").strip().lower()
            
            if cmd == 'q':
                break
            elif cmd == '':  # ENTER key for START
                print(f"{Color.MAGENTA}Pressing START button...{Color.RESET}")
                packet = GamePacket(packet_type=0x01, direction=0x09, action=0x00)
                tester.send_packet(packet, delay=0.1)
                # Release
                packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
                tester.send_packet(packet, delay=0)
            elif cmd == 'a':
                packet = GamePacket(packet_type=0x01, direction=0x03, action=0x00)
                tester.send_packet(packet, delay=0)
            elif cmd == 'd':
                packet = GamePacket(packet_type=0x01, direction=0x04, action=0x00)
                tester.send_packet(packet, delay=0)
            elif cmd == ' ' or cmd == 'space':
                packet = GamePacket(packet_type=0x01, direction=0x00, action=0x01)
                tester.send_packet(packet, delay=0)
                time.sleep(0.1)
                # Release fire
                packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
                tester.send_packet(packet, delay=0)
            elif cmd == 's':
                packet = GamePacket(packet_type=0x01, direction=0x00, action=0x00)
                tester.send_packet(packet, delay=0)
            else:
                print(f"{Color.RED}Unknown command: {cmd}{Color.RESET}")
    
    except KeyboardInterrupt:
        print(f"\n{Color.YELLOW}Interrupted{Color.RESET}")
    finally:
        tester.disconnect()


def main():
    parser = argparse.ArgumentParser(
        description='Test FPGA Space Invaders game via UART (with START button support)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python test_game_with_start.py --port COM4
  python test_game_with_start.py --port /dev/ttyUSB0 --interactive
  python test_game_with_start.py --port /dev/ttyUSB0 --baud 9600
  
PS5 Controller Mapping:
  - Left Stick / D-Pad: Move player
  - X Button: Fire
  - OPTIONS Button: Start game (direction=0x09)
        """
    )
    
    parser.add_argument('--port', '-p', required=True,
                       help='Serial port (COM4, /dev/ttyUSB0, etc.)')
    parser.add_argument('--baud', '-b', type=int, default=115200,
                       help='Baud rate (default: 115200)')
    parser.add_argument('--interactive', '-i', action='store_true',
                       help='Interactive control mode instead of automated tests')
    
    args = parser.parse_args()
    
    tester = FPGAGameTester(port=args.port, baudrate=args.baud)
    
    if args.interactive:
        interactive_mode(tester)
    else:
        tester.run_all_tests()


if __name__ == '__main__':
    main()