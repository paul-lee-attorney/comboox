import * as React from 'react'
import {readContract} from '@wagmi/core'
import { useContractRead } from 'wagmi'
import { regCenterABI } from '../generated'


export function GetMyUserNo() {

  const getMyUserNo = useContractRead({
    address: "0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f",
    abi: regCenterABI,
    functionName: 'getAllDocsSN',
  })
  
  return (
    <div>
      <div>MyUserNo: {getMyUserNo.data}</div>
      <button onClick={() => getMyUserNo} >
        GetMyUserNo
      </button>
    </div>
  )
}
