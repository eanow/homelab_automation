var vaultpass = document.getElementById("vault_password");
var output = document.getElementById("output");
var result = document.getElementById("result");

document.querySelector(".container-fluid").style["max-width"] = "500px";
document.getElementById("unlock").addEventListener("click", unlock_run);
document.getElementById("lock").addEventListener("click", lock_run);

function unlock_run() {
    var proc = cockpit.spawn(["/home/snapraid/automation/open_vault.sh",vaultpass.value],{superuser:"require"});
    proc.done(result_success);
    proc.stream(result_output);
    proc.fail(result_fail);

    result.innerHTML = "";
    output.innerHTML = "";
}

function lock_run() {
    var proc = cockpit.spawn(["/home/snapraid/automation/close_vault.sh"],{superuser:"require"});
    proc.done(result_success);
    proc.stream(result_output);
    proc.fail(result_fail);

    result.innerHTML = "";
    output.innerHTML = "";
}

function result_success() {
    result.style.color = "green";
    result.innerHTML = "success";
}

function result_fail() {
    result.style.color = "red";
    result.innerHTML = "fail";
}

function result_output(data) {
    output.append(document.createTextNode(data));
}

function check_status(){
    var proc = cockpit.spawn(["/home/snapraid/automation/check_vault.sh"],{superuser:"require"});
    proc.stream(result_output);
}

// Send a 'init' message.  This tells the tests that we are ready to go
cockpit.transport.wait(function() { });
check_status();
