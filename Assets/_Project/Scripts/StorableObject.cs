using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StorableObject : MonoBehaviour
{
    private bool _isStored; public bool IsStored { get => _isStored; set { _isStored = value; } }
}
