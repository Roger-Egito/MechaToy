#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class BracketShaderGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Texture logo = (Texture)AssetDatabase.LoadAssetAtPath("Assets/BracketShader/logo.png", typeof(Texture));
        GUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUILayout.Box(logo, GUILayout.Width(1024 / 2.5f), GUILayout.Height(256 / 2.5f));
        GUILayout.FlexibleSpace();
        GUILayout.EndHorizontal();

        Material targetMat = materialEditor.target as Material;
        if (targetMat.shader.name != "Bracket/BracketShader") return;
        foreach (MaterialProperty property in properties)
        {
            if (property.name == "_Default") continue;
            if(property.name == "_Transparent")
            {
                if(property.floatValue == 1)
                {
                    targetMat.renderQueue = 3000;
                }
                else
                {
                    targetMat.renderQueue = 2000;
                }
            }
            materialEditor.ShaderProperty(property, property.displayName);
        }
    }
}
#endif
