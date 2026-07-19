// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title KWToken (광운 페이 데모용 토큰)
 * @dev ERC20 표준을 준수하며, 제휴 가맹점(Partner Store)에 결제 시 
 *      10% 할인된 금액(입력 금액의 90%)만 전송되는 기능을 포함합니다.
 */
contract KWToken is ERC20, Ownable {
    
    // 제휴 가맹점 여부를 저장하는 매핑 (지갑 주소 => 제휴 여부)
    mapping(address => bool) public isPartnerStore;

    /**
     * @dev 컨트랙트 배포 시 실행되는 생성자
     *      토큰 이름은 "Kwangwoon Pay", 심볼은 "KWT"로 설정합니다.
     *      배포자는 초기 발행량 100만 개(1,000,000 * 10^18)를 받습니다.
     */
    constructor() ERC20("Kwangwoon Pay", "KWT") Ownable(msg.sender) {
        // 초기 발행량: 1,000,000 KWT (데시멀 18 적용)
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /**
     * @dev 제휴 가맹점을 등록하는 함수 
     *      (해커톤 시연의 편의성을 위해 누구나 등록 가능하도록 수정함)
     * @param _store 제휴 가맹점으로 등록할 지갑 주소
     */
    function addPartnerStore(address _store) public {
        isPartnerStore[_store] = true;
    }

    /**
     * @dev 제휴 가맹점 등록을 해제하는 함수
     *      (해커톤 시연의 편의성을 위해 누구나 해제 가능하도록 수정함)
     * @param _store 제휴 가맹점에서 제외할 지갑 주소
     */
    function removePartnerStore(address _store) public {
        isPartnerStore[_store] = false;
    }

    /**
     * @dev 결제(송금)를 처리하는 핵심 함수
     *      수신자(_to)가 제휴 가맹점일 경우: 10% 자동 할인 적용 (입력 금액의 90%만 전송)
     *      수신자(_to)가 일반 지갑일 경우: 100% 정상 전송
     * 
     * @param _to 수신자(가맹점 또는 일반 사용자) 지갑 주소
     * @param _amount 결제(송금)하려는 금액
     */
    function pay(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0), "KWT: transfer to the zero address");
        
        uint256 finalAmount = _amount;

        // 수신자가 제휴 가맹점인지 확인
        if (isPartnerStore[_to]) {
            // 제휴 가맹점인 경우: 결제 금액의 90%만 전송되도록 계산 (10% 할인)
            finalAmount = (_amount * 90) / 100;
            
            // 할인 적용 시, 사용자가 잔액이 부족하면 안되므로 체크 (보낼 금액 기준)
            require(balanceOf(msg.sender) >= finalAmount, "KWT: transfer amount exceeds balance");
        } else {
            // 일반 송금 시
            require(balanceOf(msg.sender) >= finalAmount, "KWT: transfer amount exceeds balance");
        }

        // ERC20의 내부 _transfer 호출 (msg.sender -> _to)
        _transfer(msg.sender, _to, finalAmount);
        
        return true;
    }
}
