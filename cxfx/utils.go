// +build cxfx

package cxfx

import (
	. "github.com/SkycoinProject/cx/cx"
)

type Func_i32_i32 func(a int32, b int32)

var Functions_i32_i32 []Func_i32_i32
var freeFns map[string]*func() = make(map[string]*func(), 0)
var cSources map[string]**uint8 = make(map[string]**uint8, 0)

func opGlfwFuncI32I32(prgrm *CXProgram) {
	expr := prgrm.GetExpr()
	fp := prgrm.GetFramePointer()

	inp1, inp2, out1 := expr.Inputs[0], expr.Inputs[1], expr.Outputs[0]
	packageName := ReadStr(fp, inp1)
	functionName := ReadStr(fp, inp2)
	callback := func(a int32, b int32) {
		var inps [][]byte = make([][]byte, 2)
		inps[0] = FromI32(a)
		inps[1] = FromI32(b)
		PROGRAM.Callback(expr, functionName, packageName, inps)
	}

	Functions_i32_i32 = append(Functions_i32_i32, callback)
	WriteI32(GetFinalOffset(fp, out1), int32(len(Functions_i32_i32)-1))
}

func opGlfwCallI32I32(prgrm *CXProgram) {
	expr := prgrm.GetExpr()
	fp := prgrm.GetFramePointer()

	inp1, inp2, inp3 := expr.Inputs[0], expr.Inputs[1], expr.Inputs[2]
	index := ReadI32(fp, inp1)
	count := int32(len(Functions_i32_i32))
	if index >= 0 && index < count {
		Functions_i32_i32[index](ReadI32(fp, inp2), ReadI32(fp, inp3))
	}
}
