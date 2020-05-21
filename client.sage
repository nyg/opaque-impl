import argparse
import socket
import traceback

import opaque.client as opq_client
from opaque.common import send_json, recv_json

# Define register and login operations
parser = argparse.ArgumentParser()
parser.add_argument('-op', '--operation', required=True, metavar='OP', choices=['register', 'login'], help='...')
args = parser.parse_args()


def init_socket():
    server_address = ('localhost', 10001)
    print('Connecting to {} port {}…'.format(*server_address))
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(server_address)
    return sock


try:
    sock = init_socket()

    def send(**kwargs):
        return send_json(sock, **kwargs)

    def recv():
        return recv_json(sock)

    if args.operation == 'register':
        opq_client.register(send, recv)

    elif args.operation == 'login':
        SK, sid, ssid = opq_client.login(send, recv)
        if SK is None:
            raise ValueError()
        else:
            print(SK.hex())  # debug only

except:
    #traceback.print_exc()  # debug only
    print('Error')

else:
    print('Ok')

finally:
    print('Closing socket.')
    sock.close()
