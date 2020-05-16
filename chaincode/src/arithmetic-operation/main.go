package main

import (
	"fmt"

	"github.com/shok1122/fabric/core/chaincode/shim"
	"github.com/shok1122/fabric/protos/peer"
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

	switch fn; {
	case "set":
		result, err = set(stub, args)
	case "get":
		result, err = get(stub, args)
	default:
		return shim.Error(fmt.Errorf("Incorrect function (name:%s)", fn))
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
		return "", fmt.Errof("Incorrect arguments")
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

func main() {
	err := shim.Start(new(ArithmeticOperation))
	if err != nil {
		fmt.Printf("Error starting ArithmeticOperation chaincode (error:%s)", err)
	}
}
