using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class ProgressIndicator : MonoBehaviour
{
    private int _progressLevel = 0; public int ProgressLevel => _progressLevel; 
    private int _progressMaxLevel = 8; public int ProgressMaxLevel => _progressMaxLevel;

    public void ProgressObjective() { _progressLevel++; UpdateProgressText(); }
    public void RegressObjective() { _progressLevel--; UpdateProgressText(); }

    private void UpdateProgressText() => GetComponent<TextMeshPro>().text = $"Progress: {ProgressLevel}/{ProgressMaxLevel}";
}
