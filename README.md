# grandstream-ata-password-reset

Set a new admin password on a Grandstream ATA through **HTTP auto-provisioning**. You need a DHCP server that can send option 66 and a static web server.

## How it works

```
 ┌──────────┐  1. DHCP request          ┌─────────────┐
 │          │ ────────────────────────▶ │ DHCP server │
 │  HT801   │ ◀──────────────────────── │  option 66  │
 │   ATA    │    IP + option 66 =       └─────────────┘
 │          │    "http://<server>"
 │          │                           ┌─────────────┐
 │          │  2. GET /cfg<mac>.xml     │ web server  │
 │          │ ────────────────────────▶ │ (darkhttpd) │
 │          │ ◀──────────────────────── │             │
 └──────────┘    <P2>new-password</P2>  └─────────────┘
       3. ATA applies the config → web UI login works with the new password
```

1. When the ATA starts, it gets an IP address from the DHCP server. **DHCP option 66** gives the ATA the address of its provisioning server. Grandstream devices accept a full URL in option 66, for example `http://192.0.2.5`.
2. The ATA downloads `cfg<mac>.xml` from the provisioning server. `<mac>` is the MAC address of the ATA, in lowercase, with no separators. Example: `cfg000b82aabbcc.xml`.
3. The file is a Grandstream **P-value** XML file. Each setting has a number. **`P2` is the admin password.** The ATA applies the settings in the file.

## Procedure

### 1. Get the MAC address

1. Find the MAC address on the label on the bottom of the ATA.
2. If the label is missing, find the MAC address in the lease list of your DHCP server.

Grandstream MAC addresses start with `00:0B:82`.

### 2. Set DHCP option 66

1. Open the example file for your DHCP server:

   | DHCP server | File |
   |---|---|
   | MikroTik RouterOS | [`dhcp/mikrotik.rsc`](dhcp/mikrotik.rsc) |
   | dnsmasq (Pi-hole, OpenWrt) | [`dhcp/dnsmasq.conf`](dhcp/dnsmasq.conf) |
   | ISC dhcpd | [`dhcp/dhcpd.conf`](dhcp/dhcpd.conf) |

2. Replace the example MAC address with the MAC address of your ATA.
3. Replace the example URL with the URL of your web server.
4. Apply the configuration to your DHCP server.

The examples send option 66 only to the ATA. Other devices on the network do not get the option.

### 3. Prepare the config file

1. Copy [`examples/cfg000b82aabbcc.xml`](examples/cfg000b82aabbcc.xml) to a new folder, for example `./prov`.
2. Change the file name to `cfg<mac>.xml`. Use the MAC address of your ATA.
3. Write the same MAC address in the `<mac>` element in the file.
4. Write the new admin password in the `<P2>` element.

### 4. Start the web server

1. Start a static web server on port 80 that serves the folder. Use one of these commands:

   ```sh
   # Python (no installation necessary)
   sudo python3 -m http.server 80 --directory ./prov

   # darkhttpd
   sudo darkhttpd ./prov --port 80
   ```

2. Make sure that the web server sends the file:

   ```sh
   curl http://<server>/cfg000b82aabbcc.xml
   ```

To run darkhttpd as a service, use the OpenRC or systemd example in [`darkhttpd/`](darkhttpd/).

### 5. Restart the ATA and log in

1. Disconnect the power cable from the ATA.
2. Wait 10 seconds.
3. Connect the power cable.
4. Open `http://<ata-ip>` in a web browser.
5. Log in with the user name `admin` and the password from `<P2>`.

### 6. Troubleshooting

If the login does not work, examine the access log of the web server. These are the requests that the tested ATA sent at each start:

```
GET /cfg000b82aabbcc      404   ← the ATA tries the name without .xml first
GET /cfg000b82aabbcc.xml  200   ← the config file
GET /ht801fw.bin          404   ← firmware check, no action necessary
```

If the log shows no request from the ATA, the ATA did not get option 66. Examine the DHCP configuration.

The User-Agent in the log shows the model and the firmware version. Example: `Grandstream Model HW HT801 V1.1A SW 1.0.3.7`. Use this value to identify the model.

## Configure more settings

The file [`examples/cfg-full-example.xml`](examples/cfg-full-example.xml) also sets these items:

- One SIP account, for example for Asterisk or FreePBX.
- A **hotline** (optional). The ATA dials a number immediately when you lift the handset.

The P-values come from the [FusionPBX HT802 template](https://github.com/fusionpbx/fusionpbx/tree/master/resources/templates/provision/grandstream/ht802). The HT802 has two ports. Account 2 uses different P-values (P401, P747, P735 and more). Use the template to find them.

## Important

- **The ATA downloads the config file at each start.** The file replaces the changes that you make in the web UI. Make your changes in the file, or remove option 66 when you finish.
- **The web server has no access control.** All devices on your network can download the file and read the passwords in it. Stop the web server or limit access when the ATA has its configuration.
- **The ATA applies changes only when it starts.** Restart the ATA after each change to the file.
- **`admin` is a weak password.** Use a strong password if the ATA stays on a shared network.
- **Do not use port mirroring.** On a MikroTik CRS switch, port mirroring disconnected the ATA from the network. Use the access log of the web server to monitor the ATA.

## Tested on

| Model | Firmware | Result |
|---|---|---|
| HT801 V1.1A | 1.0.3.7 | ✅ P2 applied, web login works |

To add a model, open an issue or a pull request.

## License

MIT. See [LICENSE](LICENSE).
