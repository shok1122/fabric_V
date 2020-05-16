package main

import (
    "fmt"
    "testing"

    "github.com/hyperledger/fabric/core/chaincode/shim"
)

func TestAdd(t *testing.T) {
    fmt.Println("Entering TestAdd")

    // Instantiate mockStub using CarDemo as the target chaincode to unit test
    stub := shim.NewMockStub("mockStub", new(ArithmeticOperation))
    if stub == nil {
        t.Fatalf("MockStub creation failed")
    }

    result := stub.MockInvoke(
        "001",
        [][]byte{
            []byte("set"),
            []byte("A"),
            []byte("10"),
        },
    )

    if result.Status != shim.OK {
        t.Fatalf("Expected unauthorized user error to be returned (set)")
    }

    valAsbyte, err := stub.GetState("A")
    if err != nil {
        t.Errorf("Failed to get state (key:A)")
    }

    if string(valAsbyte) != "10" {
        t.Errorf("return:%s,expect:10", string(valAsbyte))
    }

    result = stub.MockInvoke(
        "001",
        [][]byte{
            []byte("add"),
            []byte("A"),
            []byte("1"),
        },
    )

    if result.Status != shim.OK {
        t.Fatalf("Expected unauthorized user error to be returned (add)")
    }

    valAsbyte, err = stub.GetState("A")
    if err != nil {
        t.Errorf("Failed to get state (key:A)")
    }

    if string(valAsbyte) != "11" {
        t.Errorf("return:%s,expect:11", string(valAsbyte))
    }
}

func TestInvokeInitArithmeticOperation(t *testing.T) {
    fmt.Println("Entering TestInvokeInitArithmeticOperation")

    // Instantiate mockStub using CarDemo as the target chaincode to unit test
    stub := shim.NewMockStub("mockStub", new(ArithmeticOperation))
    if stub == nil {
        t.Fatalf("MockStub creation failed")
    }

    resultA := stub.MockInvoke(
        "001",
        [][]byte{
            []byte("set"),
            []byte("A"),
            []byte("Alice"),
        },
    )

    resultB := stub.MockInvoke(
        "001",
        [][]byte{
            []byte("set"),
            []byte("B"),
            []byte("Bob"),
        },
    )

    if resultA.Status != shim.OK {
        t.Fatalf("Expected unauthorized user error to be returned")
    }

    if resultB.Status != shim.OK {
        t.Fatalf("Expected unauthorized user error to be returned")
    }

    valAsbytes, err := stub.GetState("A")
    if err != nil {
        t.Errorf("Failed to get state (key:A)")
    } else if valAsbytes == nil {
        t.Errorf("Asset not found (key:A)")
    }

    val := string(valAsbytes)

    if val != "Alice" {
        t.Errorf("key:A,return:%s,expect:%s", val, "Alice")
    }
}
