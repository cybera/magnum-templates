#!/bin/bash

result=$(kubeadm token create --print-join-command)
echo -n $result
