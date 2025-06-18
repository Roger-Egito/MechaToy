using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StoreCollisionController : MonoBehaviour
{
    [SerializeField] private ProgressIndicator _progressIndicator;

    private void OnTriggerEnter(Collider other)
    {
        StorableObject storableObjectScript = other.gameObject.GetComponent<StorableObject>();

        if (storableObjectScript != null)
        {
            _progressIndicator.ProgressObjective();
        }
    }

    private void OnTriggerExit(Collider other)
    {
        StorableObject storableObjectScript = other.gameObject.GetComponent<StorableObject>();

        if (storableObjectScript != null)
        {
            _progressIndicator.RegressObjective();
        }
    }
}
