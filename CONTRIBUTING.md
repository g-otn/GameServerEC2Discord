# Contributing

## Supporting a new game

You can help the project support more game dedicated servers.

1. Find a docker image for your game, or create one based on something like [steamcmd/steamcmd](https://hub.docker.com/r/steamcmd/steamcmd) or [cm2network/steamcmd](https://hub.docker.com/r/cm2network/steamcmd)

1. (Suggestion) Create a `docker-compose.yml` file for your game server and run it locally to make sure the game server image works as intended

1. (Suggestion) Please read [Custom game](./README.md#custom-game) and then test the game using `custom` game server module, where you will run the game server in AWS.
   - Fill the variables, apply the Terraform changes and try to connect and the server via DDNS
   - You don't need to set up Discord for testing, you can start/stop the server via AWS console

> [!TIP]
> You may want to set `data_volume_final_snapshot` to `false` to avoid creating final snapshots during data volume destroy, which may be done several times during testing.

### What to test

- The server is able to connected to in-game and played normally
  - If the server is started more than once, it will have a different IPv4. Sometimes DNS cache will make the DDNS domain point to the outdated IP, so you may want to connect (SSH and in-game) by referencing the IP directly.
- Connect to the server via SSH and:
  - Check `docker compose logs` in `/srv/<game id>` to see if the server is properly started
  - If needed, temporarly, disable auto shutdown to debug and inspect the logs and check for any errors. See [Useful info and commands](./README.md#useful-info-and-commands)
  - Use `htop` and `docker stats` while the container is running to check if the CPU and RAM resources are ok
  - Use `fastfetch` and `df -h` if check storage usage
- The server is properly shut down within 10-12min after the last player leaves

### Adding game defaults to the server module

1. Choose an alphanumeric, lowercase id for your game

2. Add the ID to the [`game` variable](./server/variables.tf) validation.

3. In [`server/main.tf`](./server/main.tf) modify the `game_defaults_map` local by adding a object entry, where the key is the game id and the value is an object with the following properties:
   - `game_name`: Display name used in AWS resources Name tag
   - `instance_type`: Instance type which supports and is powerful enough to run the game server. See [Server instance type](./README.md#server-instance-type)
   - `arch`: CPU architecture of the chosen instance type
   - `data_volume_size`: Storage required for game data and files, and also for auto updates if applicable (so double the server data in GB + 1GB for save files, for example).
     - Note that the Docker image is stored in the root volume so its size doesn't count
     - Remember that a 10GB data volume, without free tier offers, would on its own already cost 0.8 USD per month in us-east-2 (Ohio) region.
   - `compose_main_service_name`: For ease of use when running commands during SSH session, can be the game id
   - `main_port`: The port used for player connections, will be checked periodically to shutdown the server if no connections are established after a while
   - `sg_ingress_rules` (Optional): If the game requires more than one port to be open, you may define them here to have them automatically open in the VPC layer
   - `watch_connections`: If the game server docker image has an auto shutdown feature, you may disable the scripts which watch connections via main port monitoring

Make sure you use `coalesce()` where necessary to avoid errors with use of unset variables.

These will be the default values when selecting this game in the module variables, and should be optimized for cost but also able to run the server for a few players.

2. In the same file, inside the `main_service_map` local, create a YAML-like object which represents the docker compose service which will be placed in a `docker-compose.yml` file inside the instance

   - You may map the volumes using the `data_subfolder_path` or `data_mount_path` locals
   - Use `restart=no` so auto shutdown works properly and `stop_grace_period=2m` to allow graceful server shutdown due to spot instance interruption or Discord slash command

3. Update [`README.md`](./README.md)
   - "[Supported games](./README.md#supported-games)": Add the game name and link to docker image
   - "[Setup](./README.md#setup)": add game id to possible values options
   - "[Cost breakdown](./README.md#cost-breakdown)"
     - Use the Vantage website or the price history in AWS console Spot request page to calculate the values of the "TL;DR" list and "Notable expenses" table
   - If there's any importants notes for setting up the game server, such as setting up server password via Terraform or SSH, you may add them as a new section in [Game specific notes](./README.md#game-specific-notes)

4. Create pull request