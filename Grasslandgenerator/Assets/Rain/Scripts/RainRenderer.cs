using UnityEngine;
using System.Collections;

public class RainRenderer : MonoBehaviour
{
    Material material;

    public Shader dropShader;
    public Texture2D dropTexture;
    public Color dropColor = new Color(0.83f, 0.85f, 1f, 0.25f);
    public Vector2 dropSize = new Vector2(0.09f, 0.8f);

    //public Shader splatShader;
    //public Texture2D splatTexture;
    //public Color splatColor =  new Color(0.83f, 0.85f, 1f, 0.5f);
    //public Vector2 splatSize = new Vector2(0.2f, 0.2f);

    public bool splat = false;

    ComputeBuffer computeShaderBuffer;

    RainCreator rc;

    void Start()
    {
        material = new Material(dropShader);
    }

    void OnRenderObject()
    {
        rc = GetComponent<RainCreator>();
        
        if(rc != null && rc.getIsRunning())
        {
            computeShaderBuffer = rc.outputBuffer1;
        }
       

        if(computeShaderBuffer != null && rc.getIsRunning())
        {
            material.SetPass(0);
            material.SetBuffer("buf_Points", computeShaderBuffer);
            material.SetColor("_Color", dropColor);
            material.SetTexture("_DropSprite", dropTexture);
            material.SetVector("_Size", dropSize);
            material.SetVector("_WorldPos", transform.position);
            material.SetInt("_RainDropsCount", rc.getRainDropsCount());

            Graphics.DrawProcedural(MeshTopology.Points, computeShaderBuffer.count);
        }
       

        //if (splat)
        //{
        //    material.shader = splatShader;
        //    material.SetPass(0);
        //    material.SetBuffer("buf_Points", computeShaderBuffer);
        //    material.SetColor("_Color", splatColor);
        //    material.SetTexture("_SplatSprite", splatTexture);
        //    material.SetVector("_Size", splatSize);
        //    material.SetVector("_WorldPos", transform.position);
        //    // fragment shader discard 
        //    // geom shader discard
        //    Graphics.DrawProcedural(MeshTopology.Points, computeShaderBuffer.count);
        //}
    }

    void OnDestroy()
    {
        if(computeShaderBuffer != null)
        {
            computeShaderBuffer.Release();
        }
    }
}
