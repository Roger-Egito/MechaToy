using System.Collections;
using System.Collections.Generic;
using Unity.XR.CoreUtils;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;
using static UnityEngine.XR.Interaction.Toolkit.Inputs.Haptics.HapticsUtility;

public class XR_JumpController : MonoBehaviour
{
    public LayerMask CeilingLayer;

    [SerializeField] private float gravity = -9.81f;
    [SerializeField] private float gravityMultiplier = 1.0f;
    [SerializeField] private float gravityCap = -2f;
    
    [SerializeField] private float jumpPower = 1f;

    [SerializeField] private float flyingPower = 1f;
    [SerializeField] private float flyingCap = 2f;
    [SerializeField] private bool isFlying = false;

    [SerializeField] private float coyoteTime = 1.5f; // in seconds 
    [SerializeField] private float coyoteTimer = 0f; 
    [SerializeField] private bool isInCoyoteTime = false;

    [SerializeField] private InputActionReference jumpButton;

    [SerializeField] private CharacterController controller;

    [SerializeField] private float velocity;



    private void OnEnable() => jumpButton.action.performed += CheckForJump;
    private void OnDisable() => jumpButton.action.performed -= CheckForJump;

    private void ApplyGravity()
    {
        if (controller.isGrounded)
        {
            velocity = -0.01f;
            return;
        }

        velocity += gravity * gravityMultiplier * Time.deltaTime;

        //velocity = gravity; // No acceleration

        if (velocity < gravityCap) velocity = gravityCap;
    }

    private void CheckForJump(InputAction.CallbackContext obj)
    {
        if (controller.isGrounded && velocity < 0) Jump();
    }

    private void CheckForCeiling()
    {
        if ((controller.collisionFlags & CollisionFlags.Above) == 0) return;
        velocity = -0.01f;
    }

    public void Jump()
    {
        //velocity += Mathf.Sqrt(jumpPower * -3f * gravity);
    }

    public void FlyUpwards()
    {
        velocity += flyingPower * Time.deltaTime;
        if (velocity > flyingCap) velocity = flyingCap;
        isFlying = true;
    }

    public void StopFlying()
    {
        ApplyGravity(); // We double gravity's force for a bit
        if (velocity <= 0)
        {
            velocity = 0;
            isFlying = false;
            isInCoyoteTime = true;
        }
    }

    public void HandleCoyoteTime()
    {
        velocity = 0;
        coyoteTimer += Time.deltaTime;
        if (coyoteTimer > coyoteTime)
        {
            coyoteTimer = 0;
            isInCoyoteTime = false;
        }
    }

    private void Update()
    {
        //controller.SimpleMove(Vector3.zero);
        CheckForCeiling();

        //controller.SimpleMove(Vector3.zero);
        controller.Move(Vector3.up * velocity * Time.deltaTime);
        ApplyGravity();
        if (jumpButton.action.IsPressed()) FlyUpwards();
        else if (isFlying) StopFlying();
        else if (isInCoyoteTime) HandleCoyoteTime();
    }
}