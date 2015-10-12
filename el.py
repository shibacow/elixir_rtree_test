#!/usr/bin/env python
# -*- coding:utf-8 -*-
import gevent
from gevent import socket
from gevent.server import StreamServer
import msgpack

def handle(socket, address):
    socket.send("Hello from a telnet!")
    socket.close()

#server = StreamServer(('127.0.0.1', 5000), handle)
#server.start()

def send_data(i,sz):
    client = socket.create_connection(('127.0.0.1', 8000))
    #gevent.socket.wait_read(client.fileno())
    for p in range(sz):
        #client.send("ahoahoaho={} {} {}".format(i,sz-i,p))
        senddata = msgpack.packb([i,sz-i,p])
        client.send(senddata)
        data = client.recv(20)
        gevent.sleep(0.1)
        if i%100==0 and p%100==0:
            dt = msgpack.unpackb(data)
            print "data: {}".format(dt)

sz=1000
gevent.joinall([gevent.spawn(send_data,k,sz) for k in range(sz)])
