### digital-ocean-crud
Quick and dirty Ruby ci tool to list, add, delete [DigitalOcean](https://www.digitalocean.com) instances.

#### Requirements:
- tested and run only on Ruby 2.1.2
- update config.yml to include your DigitalOcean API Key and correct ssh keys
- your DigitalOcean boxes need ssh keys

#### Usage:
```
Usage: manage_do COMMAND [OPTIONS]

Commands
     list: list all instances
     add: add an instance - NAME is required
     delete: delete an instance - INSTANCE_ID is required
     install: run install on an instance - INSTANCE_ID is required
     bounce: restart a service on a box -INSTANCE_ID is required -SERVICE is required

Options
    -i, --instance=[INSTNACE_ID]     which instance to remove (id not name)
    -s, --service=[SERVICE]          which service to restart
    -n, --name=[NAME]                name for new instance
    -m, --image=[IMAGE]              image (id) for new instance (defaults to ubuntu-14)
    -h, --help                       help
```

#### Needed Improvements:  
- tests
- batch operations (launch N new instances)


