# Copyright © 2024 Joseph Wright <joseph@cloudboss.co>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

variable "args" {
  type        = list(string)
  description = "Arguments to the image's `ENTRYPOINT` (or `var.command` if defined). If this is *not* defined, it defaults to the image's `CMD`, unless `var.command` is defined, in which case it is ignored."

  default = null
}

variable "command" {
  type        = list(string)
  description = "Override of the image's `ENTRYPOINT`."

  default = null
}

variable "debug" {
  type        = bool
  description = "Whether or not to enable debug logging."

  default = null
}

variable "disable-services" {
  type        = list(string)
  description = "A list of services to disable at runtime if they were included in the image, e.g. with `easyto ami --services=[...]`."

  default = null
}

variable "env" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The names and values of environment variables to be passed to the image's `ENTRYPOINT` (or `var.command` if defined)."

  default = null
}

variable "env-from" {
  type = list(object({
    imds = optional(object({
      path     = string
      name     = optional(string, null)
      optional = optional(bool, null)
    }), null)
    s3 = optional(object({
      base64-encode = optional(bool, null)
      bucket        = string
      key           = string
      name          = optional(string, null)
      optional      = optional(bool, null)
    }), null)
    ssm = optional(object({
      base64-encode = optional(bool, null)
      name          = optional(string, null)
      optional      = optional(bool, null)
      path          = string
    }), null)
    secrets-manager = optional(object({
      base64-encode = optional(bool, null)
      name          = optional(string, null)
      optional      = optional(bool, null)
      secret-id     = string
    }), null)
  }))
  description = "Environment variables to be passed to the image's `ENTRYPOINT` (or `var.command` if defined), to be retrieved from the given sources."

  default = null
}

variable "init-scripts" {
  type        = list(string)
  description = "A list of scripts to run on boot. They must start with `#!` and have a valid interpreter available in the image. For lightweight images that have no shell in the container image they are derived from, `#!/.easyto/bin/busybox sh` can be used. The AMI will always have `/.easyto/bin/busybox available` as a source of utilities that can be used in the scripts. Init scripts run just before any services have started and the entry point is executed."

  default = null
}

variable "replace-init" {
  type        = bool
  description = "If `true`, the entry point will replace `init` when executed. This may be useful if you want to run your own init process. However, easyto init will still do everything leading up to the execution of the entry point, for example formatting and mounting filesystems defined in volumes, and setting environment variables."

  default = null
}

variable "security" {
  type = object({
    readonly-root-fs = optional(bool, null)
    run-as-group-id  = optional(number, null)
    run-as-user-id   = optional(number, null)
  })
  description = "Configuration of security settings."

  default = null
}

variable "shutdown-grace-period" {
  type        = number
  description = "When shutting down, the number of seconds to wait for all processes to exit cleanly before sending a kill signal."

  default = null
}

variable "sysctls" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The names and values of sysctls to set before starting the entry point."

  default = null
}

variable "volumes" {
  type = list(object({
    ebs = optional(object({
      attachment = optional(object({
        tags = list(object({
          key   = string
          value = optional(string)
        }))
        timeout = optional(number)
      }))
      device = string
      mount = object({
        destination = string
        fs-type     = string
        group-id    = optional(number, null)
        mode        = optional(string, null)
        options     = optional(list(string), null)
        user-id     = optional(number, null)
      })
    }), null)
    s3 = optional(object({
      bucket     = string
      key-prefix = optional(string, null)
      mount = object({
        destination = string
        group-id    = optional(number, null)
        mode        = optional(string, null)
        options     = optional(list(string), null)
        user-id     = optional(number, null)
      })
      optional = optional(bool, null)
    }), null)
    ssm = optional(object({
      path = string
      mount = object({
        destination = string
        group-id    = optional(number, null)
        mode        = optional(string, null)
        options     = optional(list(string), null)
        user-id     = optional(number, null)
      })
      optional = optional(bool, null)
    }), null)
    secrets-manager = optional(object({
      mount = object({
        destination = string
        group-id    = optional(number, null)
        mode        = optional(string, null)
        options     = optional(list(string), null)
        user-id     = optional(number, null)
      })
      optional  = optional(bool, null)
      secret-id = string
    }), null)
  }))
  description = "Configuration of volumes."

  default = null
}

variable "working-dir" {
  type        = string
  description = "The directory in which the entry point will be run. This defaults to the container image's `WORKDIR` if it is defined, or else `/`."

  default = null
}
