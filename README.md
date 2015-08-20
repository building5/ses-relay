# ses-relay

## Supported tags and respective `Dockerfile` links

-	[`latest`, `1`, `1.0`, `1.0.0` (*Dockerfile*)](https://github.com/building5/ses-relay/blob/v1.0/Dockerfile)
-	[`devel` (*Dockerfile*)](https://github.com/building5/ses-relay/blob/master/Dockerfile)

A [Docker][] container designed to work well as an SMTP relay for [SES][]. If
you provide it with an `SMTP_USERNAME` and `SMTP_PASSWORD`, and run it on an
EC2 instance, it will automagically relay any emails it receives to the SES
server in its region.

## Basic usage

The `ses-relay` container assumes that it's running on an Amazon EC2 instance,
but you can specifically provide `AWS_REGION` if you are running it elsewhere.

It also assumes that you want to use it from other Docker containers. If you
want to use it from other networks, you can provide `DC_RELAY_NETS`.

```bash
# Create a data container for the mail spool
$ docker run --name ses-relay-data -v /data/ses-relay busybox true
# Run the ses-relay container
$ docker run --name ses-relay \
    -e SMTP_USERNAME=xxx \
    -e SMTP_PASSWORD=xxx \
    --volumes-from ses-relay-data \
    building5/ses-relay
```

While using the data container is optional, it's highly recommended, so that you
can delete, recreate or upgrade the `ses-relay` container, if needed.

To use the relay from the host, you should add `--expose localhost:25:25` to the
`docker run` command.

To use the relay to other containers, add `--link ses-relay` when starting your
container. Your container can then reach the relay at the hostname `ses-relay`.

## Environment

 * `SMTP_USERNAME` (required) - Amazon SES user name.
 * `SMTP_PASSWORD` (required) - Amazon SES password. This is [different from
   the IAM password][ses-password], so be sure you generate the right password.
 * `AWS_REGION` - AWS region for the SES server. Defaults to the region of
   the instance.
 * `DC_RELAY_NETS` - Networks to relay email for. Defaults to the
   [Docker network][].

## Ports

 * `25` - SMTP port.

## Volumes

 * `/var/spool/exim4` - Spool directory for outgoing emails. It is recommended
   that you mount this in order for the email spool to survive reloading the
   container.

## Other info

This uses [exim][] as the SMTP relay, but that is just an implementation detail
that shouldn't affect the usage of the container.

 [Docker]: https://www.docker.com/
 [SES]: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/Welcome.html
 [ses-password]: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html
 [Docker network]: https://docs.docker.com/articles/networking/
 [exim]: http://www.exim.org/
