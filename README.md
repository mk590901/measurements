# TOIT Measurements

## Introduction
The application is a simulator of four medical indicators: blood pressure (upper and lower), oxygen, temperature and heart rate.

## Components
The main object of the application is an instance of the **TimersPool class**, which creates 5 virtual timers operating at a certain frequency. Each of these timers is responsible for the generated values: t1 - upper pressure, t2 - lower pressure, t3 - oxigen, t4 - temperature, t5 - heart rate. When the timeout is reached, the timer sends the corresponding value to the **cloud:demo/pong** topic, packing it into a json-string.

The main function starts a task, which, when receiving an event via the **cloud:demo/ping^^ channel, creates a **TimersPool**, builds the five timers discussed above and makes it possible to generate and send data within 30 seconds. Then an event is sent to the client indicating the end of the measurement session.

This app must be installed on the **ESP32**. It's located in the measurements repository. The application is installed (*via deployment*) with the command **toit -d=nuc deploy measurements2.yaml** (on ESP32 *nuc*, you controller may have other names) and uninstalled with the command **toit device -d=nuc uninstall "Measurements"**.

## Using
It should also be noted that the TOIT app is a server and should be work with a client from the *https://github.com/mk590901/cloud_measurements* repository, written in dart in the flutter environment.
