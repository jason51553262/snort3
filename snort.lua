---------------------------------------------------------------------------
-- 1. configure defaults
---------------------------------------------------------------------------

HOME_NET = 'any'
EXTERNAL_NET = 'any'
include 'snort_defaults.lua'

---------------------------------------------------------------------------
-- 2. configure inspection
---------------------------------------------------------------------------

stream = { }
stream_ip = { }
stream_icmp = { }
stream_tcp = { }
stream_udp = { }
stream_user = { }
stream_file = { }

arp_spoof = { }
back_orifice = { }
dns = { }
imap = { }
netflow = {}
normalizer = { }
pop = { }
rpc_decode = { }
sip = { }
ssh = { }
ssl = { }
telnet = { }

cip = { }
dnp3 = { }
iec104 = { }
mms = { }
modbus = { }
s7commplus = { }

dce_smb = { }
dce_tcp = { }
dce_udp = { }
dce_http_proxy = { }
dce_http_server = { }

-- see snort_defaults.lua for default_*
gtp_inspect = default_gtp
port_scan = default_med_port_scan
smtp = default_smtp

ftp_server = default_ftp_server
ftp_client = { }
ftp_data = { }

http_inspect = { }
http2_inspect = { }

-- see file_magic.rules for file id rules
file_id = { rules_file = 'file_magic.rules' }
file_policy = { }

js_norm = default_js_norm

appid = { }

---------------------------------------------------------------------------
-- 3. configure bindings
---------------------------------------------------------------------------

wizard = default_wizard

binder =
{
    -- port bindings required for protocols without wizard support
    { when = { proto = 'udp', ports = '53', role='server' },  use = { type = 'dns' } },
    { when = { proto = 'tcp', ports = '53', role='server' },  use = { type = 'dns' } },
    { when = { proto = 'tcp', ports = '111', role='server' }, use = { type = 'rpc_decode' } },
    { when = { proto = 'tcp', ports = '502', role='server' }, use = { type = 'modbus' } },
    { when = { proto = 'tcp', ports = '2123 2152 3386', role='server' }, use = { type = 'gtp_inspect' } },
    { when = { proto = 'tcp', ports = '2404', role='server' }, use = { type = 'iec104' } },
    { when = { proto = 'udp', ports = '2222', role = 'server' }, use = { type = 'cip' } },
    { when = { proto = 'tcp', ports = '44818', role = 'server' }, use = { type = 'cip' } },

    { when = { proto = 'tcp', service = 'dcerpc' },  use = { type = 'dce_tcp' } },
    { when = { proto = 'udp', service = 'dcerpc' },  use = { type = 'dce_udp' } },
    { when = { proto = 'udp', service = 'netflow' }, use = { type = 'netflow' } },

    { when = { service = 'netbios-ssn' },      use = { type = 'dce_smb' } },
    { when = { service = 'dce_http_server' },  use = { type = 'dce_http_server' } },
    { when = { service = 'dce_http_proxy' },   use = { type = 'dce_http_proxy' } },

    { when = { service = 'cip' },              use = { type = 'cip' } },
    { when = { service = 'dnp3' },             use = { type = 'dnp3' } },
    { when = { service = 'dns' },              use = { type = 'dns' } },
    { when = { service = 'ftp' },              use = { type = 'ftp_server' } },
    { when = { service = 'ftp-data' },         use = { type = 'ftp_data' } },
    { when = { service = 'gtp' },              use = { type = 'gtp_inspect' } },
    { when = { service = 'imap' },             use = { type = 'imap' } },
    { when = { service = 'http' },             use = { type = 'http_inspect' } },
    { when = { service = 'http2' },            use = { type = 'http2_inspect' } },
    { when = { service = 'iec104' },           use = { type = 'iec104' } },
    { when = { service = 'mms' },              use = { type = 'mms' } },
    { when = { service = 'modbus' },           use = { type = 'modbus' } },
    { when = { service = 'pop3' },             use = { type = 'pop' } },
    { when = { service = 'ssh' },              use = { type = 'ssh' } },
    { when = { service = 'sip' },              use = { type = 'sip' } },
    { when = { service = 'smtp' },             use = { type = 'smtp' } },
    { when = { service = 'ssl' },              use = { type = 'ssl' } },
    { when = { service = 'sunrpc' },           use = { type = 'rpc_decode' } },
    { when = { service = 's7commplus' },       use = { type = 's7commplus' } },
    { when = { service = 'telnet' },           use = { type = 'telnet' } },

    { use = { type = 'wizard' } }
}

---------------------------------------------------------------------------
-- 4. configure performance
---------------------------------------------------------------------------

-- use latency to monitor / enforce packet and rule thresholds
latency =
{
    packet = { max_time = 1500 },
    rule = { max_time = 200 }
}

---------------------------------------------------------------------------
-- 5. configure detection
---------------------------------------------------------------------------

references = default_references
classifications = default_classifications

ips =
{
    variables = default_variables
}

---------------------------------------------------------------------------
-- 6. configure filters
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 7. configure outputs
---------------------------------------------------------------------------

alert_fast =
{
    file = true,  -- Write to stdout, which is usually unbuffered
    packet = true -- Include packet data for better context
}

alert_syslog =
{
    facility = 'local6',
    level = 'alert',
    options = {'pid', 'ndelay', 'cons', 'perror'}
}

---------------------------------------------------------------------------
-- 8. configure tweaks
---------------------------------------------------------------------------

if ( tweaks ~= nil ) then
    include(tweaks .. '.lua')
end


---------------------------------------------------------------------------
-- configure search engine
---------------------------------------------------------------------------

search_engine = { search_method = "hyperscan" }
