wait_for_shell() {
    if is_unix; then
        try --max 24 --delay 5 rdctl shell test -f /var/run/lima-boot-done
        assert_success
        # wait until sshfs mounts are done
        try --max 12 --delay 5 rdctl shell test -d "$HOME/.rd"
        assert_success
    fi
    rdctl shell sync
}

factory_reset() {
    if [ "$BATS_TEST_NUMBER" -gt 1 ]; then
        capture_logs
    fi

    if using_npm_run_dev; then
        if is_unix; then
            run rdctl shutdown
            run pkill -f "$(readlink -f "$PATH_REPO_ROOT/node_modules")"
            run pkill -f "$(readlink -f "$PATH_RESOURCES")"
            run pkill -f "$(readlink -f "$LIMA_HOME")"
        else
            # TODO: kill `npm run dev` instance on Windows
            true
        fi
    fi
    rdctl factory-reset

    if is_windows; then
        run sudo ip link delete docker0
        run sudo ip link delete nerdctl0

        sudo iptables -F
        sudo iptables -L | awk '/^Chain CNI/ {print $2}' | xargs -l sudo iptables -X
    fi
}

# Turn `rdctl start` arguments into `npm run dev` arguments
apify_arg() {
    # TODO this should be done via autogenerated code from command-api.yaml
    perl -w - "$1" <<'EOF'
# don't modify the value part after the first '=' sign
($_, my $value) = split /=/, shift, 2;
if (/^--/) {
    # turn "--virtual-machine.memory-in-gb" into "--virtualMachine.memoryInGb"
    s/(\w)-(\w)/$1\U$2/g;
    # fixup acronyms
    s/memoryInGb/memoryInGB/;
    s/numberCpus/numberCPUs/;
    s/socketVmnet/socketVMNet/;
    s/--wsl/--WSL/;
}
print;
print "=$value" if $value;
EOF
}

start_container_engine() {
    local args=(
        --application.debug
        --application.updater.enabled=false
        --container-engine.name="$RD_CONTAINER_ENGINE"
        --kubernetes.enabled=false
    )
    if is_unix; then
        args+=(
            --application.admin-access=false
            --application.path-management-strategy rcfiles
            --virtual-machine.memory-in-gb 6
        )
    fi
    if using_networking_tunnel; then
        args+=(--experimental.virtual-machine.networking-tunnel)
    fi

    # TODO containerEngine.allowedImages.patterns and WSL.integrations
    # TODO cannot be set from the commandline yet
    image_allow_list="$(bool "$RD_USE_IMAGE_ALLOW_LIST")"
    wsl_integrations="{}"
    if is_windows; then
        wsl_integrations="{\"$WSL_DISTRO_NAME\":true}"
    fi
    mkdir -p "$PATH_CONFIG"
    cat <<EOF >"$PATH_CONFIG_FILE"
{
  "version": 7,
  "WSL": { "integrations": $wsl_integrations },
  "containerEngine": {
    "allowedImages": {
      "enabled": $image_allow_list,
      "patterns": ["docker.io"]
    }
  }
}
EOF

    if using_npm_run_dev; then
        # translate args back into the internal API format
        local api_args=()
        for arg in "${args[@]}"; do
            api_args+=("$(apify_arg "$arg")")
        done

        npm run dev -- "${api_args[@]}" "$@" &
    else
        # Detach `rdctl start` because on Windows the process may not exit until
        # Rancher Desktop itself quits.
        rdctl start "${args[@]}" "$@" &
    fi
}

# shellcheck disable=SC2120
start_kubernetes() {
    start_container_engine \
        --kubernetes.enabled \
        --kubernetes.version "$RD_KUBERNETES_PREV_VERSION" \
        "$@"
}

start_application() {
    start_kubernetes
    wait_for_apiserver

    # the docker context "rancher-desktop" may not have been written
    # even though the apiserver is already running
    if using_docker; then
        wait_for_container_engine
    fi

    # BUG BUG BUG
    # Looks like the rcfiles don't get updated via `rdctl start`
    # BUG BUG BUG
    if is_unix; then
        rdctl set --application.path-management-strategy manual
        rdctl set --application.path-management-strategy rcfiles
    fi
}

container_engine_info() {
    run ctrctl info
    assert_success
    assert_output --partial "Server Version:"
}

docker_context_exists() {
    run docker_exe context ls -q
    assert_success
    assert_line "$RD_DOCKER_CONTEXT"
}

buildkitd_is_running() {
    run rdctl shell rc-service --nocolor buildkitd status
    assert_success
    assert_output --partial 'status: started'
}

wait_for_container_engine() {
    try --max 12 --delay 10 container_engine_info
    assert_success
    if using_docker; then
        try --max 30 --delay 5 docker_context_exists
        assert_success
    else
        try --max 30 --delay 5 buildkitd_is_running
        assert_success
    fi
}
