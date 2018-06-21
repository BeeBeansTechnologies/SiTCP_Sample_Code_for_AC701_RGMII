Read this in other languages: [English](README.md), [日本語](README.ja.md)

# SiTCP Sample Code for AC701 RGMII

This is the SiTCP sample source code (RGMII version) for AC701 communication confirmation.

In this code use the module that converts the interface of AT93C46, used by SiTCP, to EEPROM (M24C08) of AC701.

This code also use a module that to operate I2C switch, PCA9548A, loaded on the AC701.


## What is SiTCP

Simple TCP/IP implemented on an FPGA (Field Programmable Gate Array) for the purpose of transferring large amounts of data in physics experiments.

* For details, please refer to [SiTCP Library page](https://www.bbtech.co.jp/en/products/sitcp-library/).
* For other related projects, please refer to [here](https://github.com/BeeBeansTechnologies).

![SiTCP](sitcp.png)
