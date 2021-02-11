job "exec-services" {
  datacenters = ["dc1"]
  type = "service"
  group "upstream" {
    network {
      mode = "bridge"
    }

    service {
      name = "exec-upstream-service"
      port = 8181
      connect {
        sidecar_service {
        }
      }
    }

    task "exec-upstream-service" {
      driver = "exec"
      config {
        command = "/bin/sh"
        args = [
          "-c",
          "echo \"starting upstream\"; while true; do printf 'HTTP/1.1 200 OK\nContent-Type: text/plain; charset=UTF-8\nServer: netcat\n\nHello, world.\n'  | nc -w 10 -p 8181 -l; sleep 1; done"
        ]
      }
    }
  }

  group "downstream" {
    network {
      mode = "bridge"
    }

    service {
      name = "exec-downstream-service"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "exec-upstream-service"
              local_bind_port = 9191
            }
          }
        }
      }
    }

    task "exec-downstream-service" {
      driver = "exec"
      config {
        command = "/bin/sh"
        args = [
          "-c",
          "echo \"starting downstream\"; echo $NOMAD_UPSTREAM_ADDR_exec_upstream_service; while true; do nc -w 1 localhost 9191; sleep 1; done"
        ]
      }
    }
  }
}
