using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.EventSystems;

public class EnemyAI : MonoBehaviour
{
    [SerializeField] private NavMeshAgent agent;
    [SerializeField] private Rigidbody rigidbody;
    [SerializeField] private Transform player;
    [SerializeField] private Transform body;

        [SerializeField] private float health;
    [SerializeField] private bool damaged;

    [SerializeField] LayerMask whatIsGround, whatIsPlayer;

    // Patrolling
    [SerializeField] private Vector3 walkPoint;
    private bool walkPointSet;
    [SerializeField] private float walkPointRange;

    // Attacking
    [SerializeField] private float timeBetweenAttacks;
    [SerializeField] private bool alreadyAttacked;

    // States
    [SerializeField] private float sightRange, attackRange;
    [SerializeField] private bool playerInSightRange, playerInAttackRange;

    [SerializeField] private List<MonoBehaviour> grabScripts;

    private void SearchWalkPoint()
    {
        // Calculate random point in range
        float randomX = Random.Range(-walkPointRange, walkPointRange);
        float randomZ = Random.Range(-walkPointRange, walkPointRange);

        walkPoint = new Vector3(body.position.x + randomX, body.position.y, body.position.z + randomZ);
    
        if (Physics.Raycast(walkPoint, -body.up, 2f, whatIsGround)) walkPointSet = true;
    }

    private void Patrolling()
    {
        if (!walkPointSet) SearchWalkPoint();
        else agent.SetDestination(walkPoint);

        Vector3 distanceToWalkPoint = body.position - walkPoint;

        //Walkpoint Reached
        if (distanceToWalkPoint.magnitude < 1f) walkPointSet = false;
    }    
    private void Chasing()
    {
        agent.SetDestination(player.position);
    }    
    private void Attacking()
    {
        agent.SetDestination(transform.position);
        transform.LookAt(player);

        if (!alreadyAttacked)
        {
            // Fill rest of attack code here. For now, I will make the enemy itself take damage.
            TakeDamage(1);

            alreadyAttacked = true;
            Invoke(nameof(ResetAttack), timeBetweenAttacks);
        }
    }

    private void ResetAttack()
    {
        alreadyAttacked = false;
    }

    private void TakeDamage(int dmg)
    {
        health -= dmg;
        //if (health <= 0)
        //{
        //    Destroy(gameObject);
        //    return;
        //}

        damaged = true;

        StartCoroutine(ApplyKnockback());
        

        //yield return new WaitForFixedUpdate();
        //float knockbackTime = Time.time;
        //yield return new WaitUntil(
        //    () => rigidbody.velocity.magnitude < 0.5 || Time.time > knockbackTime + 2000
        //    );
        //yield return new WaitForSeconds(0.25f);
        //
        //rigidbody.velocity = Vector3.zero;
        //rigidbody.angularVelocity = Vector3.zero;
        //rigidbody.useGravity = false;
        //rigidbody.isKinematic = true;
        //agent.Warp(body.position);
        //agent.enabled = true;
        //
        //yield return null;
    }

    private IEnumerator ApplyKnockback()
    {
        agent.enabled = false;
        rigidbody.useGravity = true;
        rigidbody.isKinematic = false;

        //yield return new WaitForSeconds(0.5f);
        yield return new WaitForFixedUpdate(); // ensure physics frame has begun

        Vector3 knockbackDirection = (transform.position - player.position).normalized;
        rigidbody.AddForce(knockbackDirection * 5f, ForceMode.Impulse);

        yield return new WaitForSeconds(1f);

        if (health <= 0)
        {
            foreach (MonoBehaviour script in grabScripts)
            {
                script.enabled = true;
            }
            yield break;
        }        
        rigidbody.velocity = Vector3.zero;
        rigidbody.angularVelocity = Vector3.zero;
        rigidbody.useGravity = false;
        rigidbody.isKinematic = true;
        agent.Warp(body.position); // sync navmesh
        agent.enabled = true;
        
        damaged = false;
    }

    private void Update()
    {
        if (damaged) return;

        playerInSightRange = Physics.CheckSphere(body.position, sightRange, whatIsPlayer);
        playerInAttackRange = Physics.CheckSphere(body.position, attackRange, whatIsPlayer);
        
        if (playerInSightRange) {
            if (playerInAttackRange) Attacking();
            else Chasing();
        } else Patrolling();
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(body.position, attackRange);
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(body.position, sightRange);
    }
}
