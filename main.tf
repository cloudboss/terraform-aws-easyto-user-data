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

locals {
  # Strip out as many null values as possible to reduce user data size.
  env_from_denulled = [for name, ev in var.env-from :
    { for k, v in ev : k => v if v != null }
  ]
  volumes_denulled_firstpass = [for name, vol in var.volumes :
    { for k, v in vol : k => v if v != null }
  ]
  volumes_denulled = [for vol in local.volumes_denulled_firstpass : {
    for source_key, source in vol : source_key => merge(
      { for k, v in source : k => v if v != null && k != "mount" && k != "attachment" },
      { mount = { for k, v in source.mount : k => v if v != null } },
      try(source.attachment, null) == null
      ? {}
      : { attachment = { for k, v in source.attachment : k => v if v != null } },
    )
  }]

  user_data_nully = {
    args                  = var.args
    command               = var.command
    debug                 = var.debug
    disable-services      = var.disable-services
    env                   = var.env
    env-from              = local.env_from_denulled
    init-scripts          = var.init-scripts
    modules               = var.modules
    replace-init          = var.replace-init
    security              = var.security
    shutdown-grace-period = var.shutdown-grace-period
    sysctls               = var.sysctls
    volumes               = local.volumes_denulled
    working-dir           = var.working-dir
  }

  user_data = { for k, v in local.user_data_nully : k => v if v != null }
}

output "value" {
  value = yamlencode(local.user_data)
}
