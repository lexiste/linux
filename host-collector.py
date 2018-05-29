#!/usr/bin/python3

import sys
import argparse

def get_host_ciphers():
      """
         to get list of supported ciphers
      """
      return

def get_host_screenshot():
      """
         to get list a screen shot from the server
      """
      return
	
def main():
      parser = argparse.ArgumentParser(add_help=True)
      parser.add_argument('-v', '--verbose', help='increase output verbosity', action='store_true')
      parser.add_argument('-f', '--file', help='list of IP addresses and port numbers in IP:PORT format')
      parser.add_argument('--host', help='host IP address to collect')
      parser.add_argument('--port', help='port number to collect (default:%(default)s)', default=443)
      args = parser.parse_args()

      if args.verbose:
         print("verbose mode enabled")

      if args.file:
         print("file name submitted: ", args.file)
         input_file = args.file.strip()

      else:
         host_ip = args.host.strip()
         port_id = args.port.strip()
         print("host:",host_ip,":",port_id)


      return
	
main()
