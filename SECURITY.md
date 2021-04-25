## Security

Security is an important aspect of running validator nodes. This cookbook made some deliberate changes to the upstream setup procedures to avoid running the Elrond node services under a sudo-enabled user for example. Another example for those changes is that we use separate users for every node service and these services themselves are unable to read another service's config or key i.e they are isolated from each other. They run under system users which lack any special privileges.

### Filesystem Security

By default, for validators, the node keys are read from Hashicorp Vault via our `elrond_keyvault` custom Chef/Cinc resource. However, to avoid maintaining a persistent connnection to our Vault, which by itself can be a security issue as it would require long lived tokens, the keys are exported locally on the first run. Only the `root` user of the machine has access to the local key store. These keys are also copied over for each node configuration.

The implication of the previous paragraph is that the keys are exported in plaintext for the local filesystem of the server running the node(s). This means, at minimum, full disk/stackable filesystem encryption is required. This statement is true whether you use our setup tools or the upstream setup tools.

Cloud services (e.g AWS) provide the possibility for doing EBS encryption for example. Some cloud services do not have this feature. Bare metal servers, even less so. Therefore, additional measures are required, such as LUKS to create a full disk encryption setup. At minimum, in these circumstances, encrypting `/opt` via LUKS or a stackable filesystem encryption scheme (such as ecryptfs or encfs) is required.

Note that you can do LUKS / stackable filesystem encryption even on cloud services providing full disk encryption for their respective block stores. The drawback of either LUKS or stackable filesystem encryption schemes is that a key must be provided in order to mount the encypted filesystem and this can not be done securely without human intervention. Technically, you _can_ automate this, but you wouldn't tape your key to your main door, would you?

Essentially, dealing with disk encryption yourself means rebooting a machine has to be personally attended.

Also, these secrets live in memory. There may be a risk for these memory pages to be swapped to disk, so if a swap device is in use, that device must be encrypted. An alternative to disk swapping may be [zram](https://en.wikipedia.org/wiki/Zram) - besides avoding swapping memory pages to disk, in general, it is also faster than disk swap as the system RAM provides much higher bandwidth and much smaller latency compared even with the fastest NVMe SSD's and the cost in CPU for compress/decompress memory pages is pretty negligible.

### Network Security

We create the minimum necessary for running the Elrond nodes. All of the API endpoints are bound to 127.0.0.1, so they are not accessible from outside the machine running the nodes. The only publicly available listeners that are created by this cookbook are the P2P node listeners which are necessary for the functioning of the Elrond network itsef.

In general terms, only these P2P ports must be accessible from the public internet. Any administrative interface (e.g SSH) should be restricted just to the people who are dealing with the server administration.

### Datacentre Security

This is an area where we have seen actual bad advice given by various members of the Elrond Network Validators Community (n.b these are not representatives of Elrond Network).

Essentially:

 * Do not run Elrond nodes on cheap VPS providers. As we live in a post 2018-world where exploitation of hardware bugs became an entire field of research, small vendors most likely do not have the experts needed to properly isolate virtualised workloads to make sure malicious tenants can't access the data of legitimate customers. Like cryptography, computing has become a field reserved for experts. For those interested, this is a very interesting session which have been fortunate enough to attend: [Speculation & leakage: Timing side channels & multi-tenant computing](https://www.youtube.com/watch?v=kQ4H6XO-iao). TL;DR large vendors, such as AWS, afford to run bespoke hardware to protect their customer and have computing experts hired to deal with these kind of issues. A cheap VPS provider most likely does not.
 * Do not run Elrond nodes on untrustworthy dedicated servers providers. This is a bit vague - we know. Essentially, some vendors don't make the news when they drop the ball (it isn't necessarily newsworthy), but breaches happen more often that people would think. They are also underreported. One famous example is NordVPN (who make a lot of claims w.r.t their security) who got pwned by [their service provider dropping the ball](https://www.theverge.com/2019/10/21/20925065/nordvpn-server-breach-vpn-traffic-exposed-encryption).

While most of these attacks are opportunistic, disaster has to strike only once. If you can't personally verify a smaller vendor, then an established service provider has better governance most likely.

### OS Security

It is best to use hardened deployments rather than leaving everything to their defaults (which may not be great to begin with). Our aim is to follow the [CIS Benchmarks](https://learn.cisecurity.org/benchmarks) w.r.t server security.

Should we write any tooling for supporting Elrond Network deployments, we shall make them available for the community.

On top of that, to minimise the potential impact of a kernel vulnerability, dynamic kernel patching is a top recommendation. Examples: Kernel Care (from CloudLinux, does not require CloudLinux itself), Ksplice (for Oracle Cloud customers is included at no additional cost), Canonical Livepatch (for Ubuntu Advantage subscribers). The additional benefit is that it reduces the need for rebooting a machine, therefore minimising the inconvenience of unlocking encrypted filesystems for example.

### Memory Security

This is a relatively new field as there's only one maintream vendor who provides such feature: AMD (for their Epyc and Ryzen Pro series). But [when Cloudflare pays attention](https://blog.cloudflare.com/securing-memory-at-epyc-scale/), we pay attention.

This area is still subject to research as for the time being, from the large cloud providers, only [Google has made some definitive progress](https://www.zdnet.com/article/googles-confidential-vms-may-change-the-public-cloud-market/), despite AWS and Oracle having AMD Epyc in their offering. An alternative would be the dedicated server providers who deploy AMD Epyc based servers in their datacentres, provided they enable the support.
