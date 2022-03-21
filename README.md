# OIPA

Oracle Insurance Policy Administration (OIPA) is a rules-driven system that supports every stage of life, annuity and group insurance, including underwriting, contract changes, claims, and more. With Oracle's solution, you make the important decisions and your system enforces them. Read more [here](https://www.oracle.com/a/ocom/docs/industries/financial-services/oipa-life-insurance-solution-ds.pdf)

In this repo you will find a collection of Vagrant projects that provision Oracle and other software automatically, using Vagrant, an Oracle Linux box, and shell scripts. Unless indicated otherwise, these projects work with both Oracle VM VirtualBox and libvirt/KVM.

## Prerequisites

All projects in this repository require Vagrant and either Oracle VM VirtualBox or libvirt/KVM with the vagrant-libvirt plugin. 

### If using VirtualBox

1. Install [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://vagrantup.com/)

### If using libvirt/KVM on Oracle Linux

1. Read [Philippe's blog post](https://blogs.oracle.com/linux/getting-started-with-the-vagrant-libvirt-provider-for-oracle-linux) for instructions on using the Vagrant libvirt provider

## Getting started

1. Clone this repository `git clone https://github.com/calittle/oipa`
2. Change into the desired project folder, e.g. `oipa/11.3.0/vagrant`
3. Follow the README.md instructions inside the folder

## Attribution

This project was forked from Oracle's Database Vagrant [project](https://github.com/oracle/vagrant-projects). We stand on the shoulders of giants!

## Contributing

This project welcomes contributions from the community. Before submitting a pull
request, please [review our contribution guide](./CONTRIBUTING.md).

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security
vulnerability disclosure process.


## Feedback

Please provide feedback of any kind via Github issues on this repository.
