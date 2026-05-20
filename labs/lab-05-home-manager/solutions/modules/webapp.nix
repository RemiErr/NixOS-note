# Lab 5 標準答案：modules/webapp.nix

{ config, pkgs, lib, ... }:

let
  myappScript = pkgs.writeShellScript "myapp-server" ''
    #!/usr/bin/env bash
    export PATH="${pkgs.python3}/bin:$PATH"
    echo "myapp starting on 127.0.0.1:8080"

    python3 - <<'PYEOF'
import http.server
import socketserver

PORT = 8080
HOST = "127.0.0.1"

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        message = b"Hello from NixOS!\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(message)))
        self.end_headers()
        self.wfile.write(message)

    def log_message(self, format, *args):
        print(f"[myapp] {self.address_string()} - {format % args}")

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer((HOST, PORT), MyHandler) as httpd:
    print(f"Serving on http://{HOST}:{PORT}")
    httpd.serve_forever()
PYEOF
  '';
in
{
  users.users.myapp = {
    isSystemUser = true;
    group        = "myapp";
    description  = "myapp web application service user";
  };

  users.groups.myapp = {};

  systemd.services.myapp = {
    description = "My NixOS Web Application";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "network.target" ];

    serviceConfig = {
      User             = "myapp";
      Group            = "myapp";
      ExecStart        = "${myappScript}";
      WorkingDirectory = "/tmp";
      Restart          = "on-failure";
      RestartSec       = "5s";
      PrivateTmp       = true;
      ProtectSystem    = "strict";
      ProtectHome      = true;
      NoNewPrivileges  = true;
      StandardOutput   = "journal";
      StandardError    = "journal";
    };
  };
}
