A few years ago, before [Ubuntu Minimal](https://wiki.ubuntu.com/Minimal)
existed, I was playing around with creating small Ubuntu AMIs from scratch.
Someone on Reddit was doing something similar, so I am publishing my notes and
scripts.

The approach I used was to create an install in an EBS volume using
`debootstrap` (via [mkosi](https://github.com/systemd/mkosi), then taking a
snapshot of the volume and turning it into an AMI. It did work, but these days
I would just use Ubuntu Minimal.

A much more complete example of using the Buildroot embedded Linux distribution
to create AMIs is here: https://github.com/cogini/buildroot_ec2
