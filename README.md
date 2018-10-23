
# Manage App Services

Stop, start or verify all app services in a resource group

## Getting Started

There are a number of Azure DevOps extensions out there to stop or start app services, but all of them seem to target only a specific app service.  I couldn't find any that would discover all app services in a resource group and stop or start them.  Even fewer extensions handled the stopping and starting of any webjobs, so I wrote this.  Mostly, this was to be used in automation for disaster recovery where we needed to stop and start an entire region.  But, I added the ability to verify that all apps are started since it was a simple addition to the extension.

### Prerequisites
None.

## Configuration
This is fairly self-explanatory and I've included comments for the different options in the GUI.

![](Screenshot1.jpeg)


## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* Craig Boroson 

See also the list of [contributors](https://github.com/cboroson/PD-Trigger/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

