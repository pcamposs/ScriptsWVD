# ScriptsWVD

The main objective of this script is support the Rush Hour, putting available X Vms.

The intent of this Script is a Complement of the Auto Scale Microsoft Script https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-scaling-script

## What it is the dieference between a Common Start VM Script and this Script? 

This Script asume that you have Running the Microsoft Autoscale Script, with that your machines are Stopped in Off Peak Our, leaving a couple of Vm Running (Ejemple 2 of 20).

If you "Max session limit" parameter by example is 10, you can support a rush Hous of 20 user, if you have 25 user rush hour (Time line 5-10 min) 5 user can't find resource to connect, and they want to whait to start a new VM by Microsoft Scaling Script. if my Rush hours is 50 Users, it is a very bad "Feeling" of service.

This script Start a number X the Vms from the pool Befor de Rush Hour, but, find the availables machine, you don't need to know the name of the machines to start.

You can change the numbers the Vms to start on WeekDay (Default) and the Weekend days


