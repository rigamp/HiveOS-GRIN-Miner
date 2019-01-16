
#########################################
### LOGGING CONFIGURATION             ###
#########################################

[logging]

# Whether to log to stdout
log_to_stdout = true

# Log level for stdout: Critical, Error, Warning, Info, Debug, Trace
stdout_log_level = "Info"

# Whether to log to a file
log_to_file = true

# Log level for file: Critical, Error, Warning, Info, Debug, Trace
file_log_level = "Debug"

# Log file path
log_file_path = "/var/log/miner/grin_auto/grin_auto.log"

# Whether to append to the log file (true), or replace it on every run (false)
log_file_append = true

#########################################
### MINING CLIENT CONFIGURATION       ###
#########################################

[mining]

# whether to run the tui
run_tui = true


stratum_server_addr = "%%SERVER%%"
stratum_server_login = "%%LOGIN%%"
stratum_server_password = "%%PASS%%"

# whether tls is enabled for the stratum server
stratum_server_tls_enabled = false

%%PLUGINS%%
