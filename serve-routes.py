#!/usr/bin/env python3
import http.server
import socketserver

PORT = 9000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

Handler = MyHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving routes.yaml at http://localhost:{PORT}/routes.yaml")
    httpd.serve_forever()
