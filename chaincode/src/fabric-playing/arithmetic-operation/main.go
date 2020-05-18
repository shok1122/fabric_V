package main

import (
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type ArithmeticOperation struct {
}

func (t *ArithmeticOperation) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

func (t *ArithmeticOperation) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	fn, args := stub.GetFunctionAndParameters()

	var result string
	var err error

	switch (fn) {
	case "set":
		result, err = set(stub, args)
	case "get":
		result, err = get(stub, args)
	case "add":
		result, err = add(stub, args)
	default:
		return shim.Error("Incorrect function (name:-)")
	}

	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte(result))
}

func set(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("Incorrect arguments")
	}

	err := stub.PutState(args[0], []byte(args[1]))
	if err != nil {
		return "", fmt.Errorf("Failed to set asset (key:%s,value:%s)", args[0], args[1])
	}

	return args[1], nil
}

func get(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 1 {
		return "", fmt.Errorf("Incorrect arguments")
	}

	val, err := stub.GetState(args[0])
	if err != nil {
		return "", fmt.Errorf("Failed to get (key:%s)", args[0])
	}
	if val == nil {
		return "", fmt.Errorf("Asset not found (key:%s)", args[0])
	}

	return string(val), nil
}

func add(stub shim.ChaincodeStubInterface, args[]string) (string, error) {

	var i1, i2, i3 int
	var err error
	var val []byte

	if len(args) != 2 {
		return "", fmt.Errorf("Incorrect arguments")
	}

	val, err = stub.GetState(args[0])
	if err != nil {
		return "", fmt.Errorf("Failed to get (key:%s)", args[0])
	}
	if val == nil {
		return "", fmt.Errorf("Asset not found (key:%s)", args[0])
	}

	i1, err = strconv.Atoi(string(val))
	if err != nil {
		return "", fmt.Errorf("Failed to convert to string (val:%+v)", val)
	}

	i2, err = strconv.Atoi(args[1])
	if err != nil {
		return "", fmt.Errorf("Failed to convert to string (val:%+v)", args[1])
	}

	i3 = i1 + i2
	err = stub.PutState(args[0], []byte(strconv.Itoa(i3)))
	if err != nil {
		return "", fmt.Errorf("Failed to set asset (key:%v,value:%v)", args[0], i3)
	}

	return string(i3), nil
}

func main() {
	err := shim.Start(new(ArithmeticOperation))
	if err != nil {
		fmt.Printf("Error starting ArithmeticOperation chaincode (error:%s)", err)
	}
}
