command=$(echo "'loadScript(\"./registerCitizens.js\"); abi.registerCitizen(0x$1, \"$2\", \"$3\", $4,{from: eth.accounts[0]});'");
command=$(echo "geth --exec $command --port 30302 attach ipc:./admin/testnet/geth.ipc");
eval $command;
