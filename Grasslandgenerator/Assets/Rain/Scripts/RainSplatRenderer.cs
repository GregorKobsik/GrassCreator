using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainSplatRenderer : MonoBehaviour {

    Material material;

    public Shader splatShader;
    public Texture2D splatTexture;
    public Color splatColor = new Color(0.83f, 0.85f, 1f, 0.5f);
    public Vector2 splatSize = new Vector2(0.06f, 0.06f);

    ComputeBuffer computeShaderBuffer;

    

    // Use this for initialization
    void Start () {
        material = new Material(splatShader);
    }

    void OnRenderObject()
    {
        RainCreator rc = GetComponent<RainCreator>();
        computeShaderBuffer = rc.outputBuffer2;

        RainRenderer rr = GetComponent<RainRenderer>();

        material.SetPass(0);
        material.SetBuffer("buf_Points", computeShaderBuffer);
        material.SetColor("_Color", splatColor);
        material.SetTexture("_SplatSprite", splatTexture);
        material.SetVector("_Size", splatSize);
        material.SetVector("_RainSize", rr.dropSize);
        material.SetVector("_WorldPos", transform.position);
        // fragment shader discard 
        // geom shader discard
        Graphics.DrawProcedural(MeshTopology.Points, computeShaderBuffer.count);
    }

    void OnDestroy()
    {
        if(computeShaderBuffer != null)
        {
            computeShaderBuffer.Release();
        }
    }
}
