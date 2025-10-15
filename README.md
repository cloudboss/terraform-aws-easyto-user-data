# easyto-user-data

This module outputs a string to be used as EC2 user data for an instance created from an [easyto](https://github.com/cloudboss/easyto) image.

See the [easyto documentation](https://github.com/cloudboss/easyto?tab=readme-ov-file#user-data) for more details on easyto.

## Example

```hcl
module "user_data" {
  source  = "cloudboss/easyto-user-data/aws"
  version = "0.x.0"

  env = [
    {
      name  = "TS_ACCEPT_DNS"
      value = tostring(var.tailscale.accept_dns)
    },
    {
      name  = "TS_EXTRA_ARGS"
      value = join(" ", var.tailscale.extra_args)
    },
    {
      name  = "TS_ROUTES"
      value = join(",", local.routes)
    },
    {
      name  = "TS_STATE_DIR"
      value = var.tailscale.state_dir
    },
    {
      name  = "TS_TAILSCALED_EXTRA_ARGS"
      value = join(" ", var.tailscale.tailscaled_extra_args)
    },
    {
      name  = "TS_USERSPACE"
      value = tostring(var.tailscale.userspace)
    },
  ]
  env-from = [
    {
      ssm = {
        name = "TS_AUTHKEY"
        path = var.tailscale.authkey_ssm_path
      }
    }
  ]
  init-scripts = local.init_scripts
  sysctls = [
    {
      name  = "net.ipv4.ip_forward"
      value = "1"
    },
    {
      name  = "net.ipv6.conf.all.forwarding"
      value = "1"
    },
  ]
}

module "asg" {
  source  = "cloudboss/asg/aws"
  version = "0.x.0"

  # Other attributes omitted

  user_data = {
    value = module.user_data.value
  }
}
```

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| args | Arguments to the image's `ENTRYPOINT` (or `var.command` if defined). If this is *not* defined, it defaults to the image's `CMD`, unless `var.command` is defined, in which case it is ignored. | list(string) | `null` | no |
| command | Override of the image's `ENTRYPOINT`. | list(string) | `null` | no |
| debug | Whether or not to enable debug logging. | bool | `null` | no |
| disable-services | A list of services to disable at runtime if they were included in the image, e.g. with `easyto ami --services=[...]`. | list(string) | `null` | no |
| env | A list of names and values of environment variables to be passed to the image's `ENTRYPOINT` (or `var.command` if defined). | list([object](#name-value-object)) | `null` | no |
| env-from | A list of environment variables to be passed to the image's `ENTRYPOINT` (or `var.command` if defined), to be retrieved from the given sources. | list([object](#env-from-object)) | `null` | no |
| init-scripts | A list of scripts to run on boot. They must start with `#!` and have a valid interpreter available in the image. For lightweight images that have no shell in the container image they are derived from, `#!/.easyto/bin/busybox sh` can be used. The AMI will always have `/.easyto/bin/busybox available` as a source of utilities that can be used in the scripts. Init scripts run just before any services have started and the entry point is executed. | list(string) | `null` | no |
| replace-init | If `true`, the entry point will replace `init` when executed. This may be useful if you want to run your own init process. However, easyto init will still do everything leading up to the execution of the entry point, for example formatting and mounting filesystems defined in volumes, and setting environment variables. | bool | `null` | no |
| security | Configuration of security settings. | [object](#security-object) | `null` | no |
| shutdown-grace-period | When shutting down, the number of seconds to wait for all processes to exit cleanly before sending a kill signal. | number | `10` | no |
| sysctls | The names and values of sysctls to set before starting the entry point. | list([object](#name-value-object)) | `null` | no |
| volumes | Configuration of volumes. | list([object](#volumes-object)) | `null` | no |
| working-dir | The directory in which the entry point will be run. This defaults to the container image's `WORKDIR` if it is defined, or else `/`. | list([object](#volumes-object)) | `null` | no |

## name-value object

Each `name-value` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Name of item. | string | N/A | yes |
| value | Value of item. | string | N/A | yes |

## env-from object

Each `env-from` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| imds | EC2 instance metadata service environment variable source. | [object](#imds-env-object) | null | no |
| s3 | S3 environment variable source. | [object](#s3-env-object) | null | no |
| ssm | SSM environment variable source. | [object](#ssm-env-object) | null | no |
| secrets-manager | AWS Secrets Manager environment variable source. | [object](#secrets-manager-env-object) | null | no |

## imds-env object

The `imds-env` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| path | Path of the attribute in IMDS below `/latest/meta-data`. | string | N/A | yes |
| name | Environment variable name. | string | `null` | no |
| optional | Whether or not the variable is optional. | bool | `false` | no |

## s3-env object

The `s3-env` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| base64-encode | If `true`, the value retrieved from `key` will be base64 encoded. | string | `false` | no |
| bucket | Name of S3 bucket. | string | N/A | yes |
| key | Key of item in S3 bucket. | string | N/A | yes |
| name | Environment variable name. If not defined, the value retrieved from `key` must contain JSON keys and values, and the keys will be the environment variable names. | string | `null` | no |
| optional | Whether or not the variable is optional. | bool | `false` | no |

## ssm-env object

The `ssm-env` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| base64-encode | If `true`, the value retrieved from `path` will be base64 encoded. | string | `false` | no |
| name | Environment variable name. If not defined, the value retrieved from `path` must contain JSON keys and values, and the keys will be the environment variable names. | string | `null` | no |
| optional | Whether or not the variable is optional. | bool | `false` | no |
| path | Path of the SSM parameter. | string | N/A | yes |

## secrets-manager-env object

The `secrets-manager-env` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| base64-encode | If `true`, the value retrieved from `secret-id` will be base64 encoded. | string | `false` | no |
| name | Environment variable name. If not defined, the value retrieved from `secret-id` must contain JSON keys and values, and the keys will be the environment variable names. | string | `null` | no |
| optional | Whether or not the variable is optional. | bool | `false` | no |
| secret-id | ID of the secret. | string | N/A | yes |

## security object

The `security` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| readonly-root-fs | If `true`, the root filesystem will be remounted as readonly before starting the entry point. | bool | `false` | no |
| run-as-group-id | The group ID the entry point will run as. | number | `null` | no |
| run-as-user-id | The user ID the entry point will run as. | number | `null` | no |

## volumes object

Each `volumes` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| ebs | EBS volume source. | [object](#ebs-volume-object) | `null` | no |
| s3 | S3 volume source. This is a pseudo volume that copies files from S3. | [object](#s3-volume-object) | `null` | no |
| ssm | SSM volume source. This is a pseudo volume that copies files from SSM Parameter Store. | [object](#ssm-volume-object) | `null` | no |
| secrets-manager | AWS Secrets Manager volume source. This is a pseudo volume that copies files from AWS Secrets Manager. | [object](#secrets-manager-volume-object) | `null` | no |

## ebs-volume object

The `ebs-volume` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attachment | If configured, the volume will be attached at boot time. The EC2 instance *must* have an instance profile with `ec2:DescribeVolumes` and `ec2:AttachVolume` permissions in its policy. | [object](#ebs-attachment-object) | `null` | no |
| device | The device name that will be given to the volume within the instance, for example `/dev/sda`. | string | N/A | yes |
| mount | Configuration of the volume mount. If not defined, the volume will not be mounted. | [object](#mount-object) | `null` | no |

## ebs-attachment object

The `ebs-attachment` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| tags | A list of tags used as filters to find the EBS volume using `ec2:DescribeVolumes`. The volume also must be in the same availability zone as the EC2 instance and in an available state. The filters should result in a single volume being returned, as the first one returned will be attached. | list([object](#ebs-tags-object)) | `null` | no |
| timeout | The amount of time in seconds to wait for the attachment before timing out. | number | `300` | no |

## ebs-tags object

Each `ebs-tags` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| key | The key of the tag. | string | N/A | yes |
| value | The value of the tag. If not defined, only `tag-key` will be used in the filter passed to `ec2:DescribeVolumes`. | string | `null` | no |

## mount object

The `mount` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| destination | The destination directory (mount point) of the device. | string | N/A | yes |
| fs-type | The filesystem type. Only applicable to EBS volumes. If the volume does not have a filesystem, it will be formatted. Must be one of `ext2`, `ext3`, `ext4`, or `btrfs`. | string | `null` | conditional |
| group-id | The group ID given to the mount point with `chgrp`. | string | the value of `var.security.run-as-group-id` | no |
| mode | The filesystem mode given to the mount point with `chmod`. | string | `0755` | no |
| options | A list of filesystem dependent mount options. | list(string) | `null` | no |
| user-id | The user ID given to the mount point with `chown`. | string | the value of `var.security.run-as-user-id` | no |

## s3-volume object

The `s3-volume` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bucket | Name of S3 bucket. | string | N/A | yes |
| key-prefix | Only objects in `bucket` beginning with this prefix will be returned. If not defined, the whole bucket will be copied. | string | `null` | no |
| mount | Configuration of the volume "mount" (files are copied from S3, not actually mounted). | [object](#mount-object) | N/A | yes |
| optional | Whether or not the volume is optional. | bool | `false` | no |

## ssm-volume object

The `ssm-volume` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| path | Path of the SSM parameter. | string | N/A | yes |
| mount | Configuration of the volume "mount" (files are copied from SSM Parameter Store, not actually mounted). | [object](#mount-object) | N/A | yes |
| optional | Whether or not the volume is optional. | bool | `false` | no |

## secrets-manager-volume object

The `secrets-manager-volume` object has the following structure.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| mount | Configuration of the volume "mount" (files are copied from Secrets Manager, not actually mounted). | [object](#mount-object) | N/A | yes |
| optional | Whether or not the volume is optional. | bool | `false` | no |
| secret-id | ID of the secret. | string | N/A | yes |
