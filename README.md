# Readme

This is a project to host the bits and pieces to fire up a build bot worker
that hooks up to the LLVM buildbot infrastructure.

## Preparation

Make sure you have a `bb-worker/compose-secrets/buildbot-worker-password` file
to store your password. This file won't be versioned in git. If you only have
the `*.sample` file in that directory, just copy that and remove the extension
`*.sample`.

To specify the name or admin of the buildbot worker, go to `docker-compose.yaml`
and ajust the settings accordingly. It's pretty self explanatory.

## Start and stop

We have the following make targets:

<dl>
<dt><code>start</code></dt><dd>Runs the buildbot worker in the background on localhost using a podman<br/>
 container. Upon launch, the  logs are followed in the terminal<br/>
 (see "follow-logs" target).<br/>
 It's safe to ctr-c out of this command once running and following the logs.# Upstream LLVM port choices:# lab.llvm.org:9994 = staging# lab.llvm.org:9990 = production</dd>
<dt><code>stop</code></dt><dd>Stops the bb-worker container created with "start.</dd>
<dt><code>build-image</code></dt><dd>Builds the bb-worker container image.</dd>
<dt><code>remove-container</code></dt><dd>Remove any container with the name bb-worker (if it exists).</dd>
<dt><code>follow-logs</code></dt><dd>Shows the output of the bb-worker container (see "start").<br/>
 It's safe to ctr-c out of this command, this won't stop any containers.</dd>
<dt><code>secret</code></dt><dd>Removes the bb-worker password secret (if exists) and re-creates it. </dd>
<dt><code>help</code></dt><dd>Display this help text.</dd>
<dt><code>help-html</code></dt><dd>Display this help text as an HTML definition list for better documentation generation</dd>
</dl>