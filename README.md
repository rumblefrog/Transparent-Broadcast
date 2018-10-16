# Transparent Broadcast [![Build Status](https://travis-ci.org/RumbleFrog/Transparent-Broadcast.svg?branch=master)](https://travis-ci.org/RumbleFrog/Transparent-Broadcast)
One of the simplest broadcasting plugin

# Convars

| Convar            | Description                                                 |
| ----------------- | ----------------------------------------------------------- |
| `sm_tb_interval`  | TB Broadcasting Interval [Default: **30.0**] (Min: **1.0**) |
| `sm_tb_cachelife` | TB Cache Lifespan [Default: **600.0**] (Min: **60.0**)      |
| `sm_tb_breed`     | TB Global ID Identifier [Default: **global**]               |

# Arguments

| Argument                    | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| `{CountDown:TimeStampHere}` | Displays a countdown (days, hours, minutes and seconds) till the timestamp (*Ex. 1651890499*) |
| `{AnyConvar}`               | Displays any public convar value                             |
| `{currentmap}`              | Current map name                                             |
| `{timeleft}`                | Amount of time remaining until next map                      |
| `{Color}`                   | Text [colors](https://www.doctormckay.com/morecolors.php)    |

# Database Structure

| Column       | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `id`         | Auto incremental ID (**Filled in automatically**)            |
| `message`    | Message to display (Only **chat** type supports color [argument](#arguments)) |
| `type`       | Message displaying method (**chat**, **hint**, **center**, and **menu**) |
| `breed`      | Only display the message to **global** or servers with the same **breed** [convar](#convars) |
| `name`       | Only display the message to **all** or servers with the same **game** type (tf, csgo, l4d2, etc) [Game Folder Name] |
| `admin_only` | If only visible to admins (Generic "b" flag) [0/1]           |
| `enabled` *  | If the message is enabled at all [0/1]                       |

# Notes

- You can have multiple values in **breed** column within the database by delimiting them with any characters
- You can also specify multiple **game** values using delimiters
- You may use both **breed** and **game** together for more advanced filter

# Installation

1. Extract `Transparent_Broadcast.smx` to `/addons/sourcemod/plugins`
2. Create `transparent_broadcast` entry in your `databases.cfg`

### `databases.cfg` example

```ini
"transparent_broadcast" 
{
    "driver"			"mysql"
    "host"			"localhost"
    "port"			"3306"
    "database"			"transparent_broadcast"
    "user"			"user"
    "pass"			"password"
}

```

# Native

- [Include File](https://github.com/RumbleFrog/Transparent-Broadcast/blob/master/include/Transparent_Broadcast.inc)

# Download 

#### Download the latest version from the [release](https://github.com/RumbleFrog/Transparent-Broadcast/releases) page

# License

GPL 3.0
