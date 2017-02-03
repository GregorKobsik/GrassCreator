using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;


public class CreateCPUMesh : MonoBehaviour {
    const int MESH_SIZE = 128;

    public Texture2D heightmap;

    public Material material;
    private Mesh mesh;
    private float oldHeightmapCoefficient;
    private float heightmap_coeffizient = 50;
    public UnityEngine.UI.Slider heightmap_slider;
    // Use this for initialization

    MeshFilter mf;
    MeshRenderer mr;

    void Start () {

        mr = gameObject.AddComponent<MeshRenderer>();
        mf = gameObject.AddComponent<MeshFilter>();
        MeshCollider mc = gameObject.AddComponent<MeshCollider>();

        heightmap_coeffizient = 50; //change it somehow here
        mesh = new Mesh();
        calculateMesh();
        mf.sharedMesh = mesh;
        mc.sharedMesh = mesh;

        mr.sharedMaterial = material;
        
        

	}
	
	// Update is called once per frame
	void Update () {

    }
    
    void gotHeightmapFile(FileSelector.Status status, string path)
    {
        if (path != "")
        {
            WWW www = new WWW("file://" + path);
            www.LoadImageIntoTexture(heightmap);

            calculateMesh();
            mr.sharedMaterial.SetTexture("_HeightMap", heightmap);
        }
    }


    public void changeHeightmap()
    {
        FileSelector.GetFile(gotHeightmapFile, ".png");
    }

    public void changeHeightmapCoeffizient()
    {
        heightmap_coeffizient = (float) heightmap_slider.value;
        if (mesh != null)
        {
            calculateMesh();
        }       
        material.SetFloat("_scaleHeight", heightmap_coeffizient);
    }

    void gotSplatmapFile(FileSelector.Status status, string path)
    {
        if (path.Length != 0)
        {
            WWW www = new WWW("file://" + path);
            Texture2D tex = new Texture2D(1, 1);
            www.LoadImageIntoTexture(tex);

            mr.sharedMaterial.SetTexture("_MainTex", tex);
        }
    }

    public void changeSplatmap()
    {
        FileSelector.GetFile(gotSplatmapFile, ".png");
    }
    
    public void calculateMesh()
    {
        //mesh = new Mesh();

        List<Vector3> myVertices = new List<Vector3>();
        List<int> myIndices = new List<int>();
        List<Vector2> myUV = new List<Vector2>();

        for (int z = 0; z < MESH_SIZE + 1; z++)
        {
            for (int x = 0; x < MESH_SIZE + 1; x++)
            {
                Vector2 uv = new Vector2((float)x / MESH_SIZE, (float)z / MESH_SIZE);
                float y = heightmap.GetPixel((int)(uv.x * heightmap.width), (int)(uv.y * heightmap.height)).grayscale * heightmap_coeffizient;
                myVertices.Add(new Vector3(x, y, z));
                myUV.Add(uv);
            }
        }

        for (int z = 0; z < MESH_SIZE; z++)
        {
            for (int x = 0; x < MESH_SIZE; x++)
            {
                //CCW
                //myIndices.Add(x + z * (MESH_SIZE + 1));
                //myIndices.Add(x + 1 + z * (MESH_SIZE + 1));
                //myIndices.Add(x + 1 + (z + 1) * (MESH_SIZE + 1));

                //CW
                myIndices.Add(x + 1 + (z + 1) * (MESH_SIZE + 1));
                myIndices.Add(x + 1 + z * (MESH_SIZE + 1));
                myIndices.Add(x + z * (MESH_SIZE + 1));

                //CW
                myIndices.Add(x + (z + 1) * (MESH_SIZE + 1));
                myIndices.Add(x + 1 + (z + 1) * (MESH_SIZE + 1));
                myIndices.Add(x + z * (MESH_SIZE + 1));

            }
        }

        mesh.SetVertices(myVertices);
        mesh.SetUVs(0, myUV);
        mesh.SetIndices(myIndices.ToArray(), MeshTopology.Triangles, 0, true);

        //Bounds bounds = new Bounds(new Vector3(50, 50, 50), new Vector3(100, 100, 100));
        //mesh.bounds = bounds;
        mesh.RecalculateBounds();
        mesh.RecalculateNormals();
        calculateMeshTangents(mesh);

    }

    //code copied from: http://answers.unity3d.com/questions/7789/calculating-tangents-vector4.html#
    public static void calculateMeshTangents(Mesh mesh)
    {
        //speed up math by copying the mesh arrays
        int[] triangles = mesh.triangles;
        Vector3[] vertices = mesh.vertices;
        Vector2[] uv = mesh.uv;
        Vector3[] normals = mesh.normals;

        //variable definitions
        int triangleCount = triangles.Length;
        int vertexCount = vertices.Length;

        Vector3[] tan1 = new Vector3[vertexCount];
        Vector3[] tan2 = new Vector3[vertexCount];

        Vector4[] tangents = new Vector4[vertexCount];

        for (long a = 0; a < triangleCount; a += 3)
        {
            long i1 = triangles[a + 0];
            long i2 = triangles[a + 1];
            long i3 = triangles[a + 2];

            Vector3 v1 = vertices[i1];
            Vector3 v2 = vertices[i2];
            Vector3 v3 = vertices[i3];

            Vector2 w1 = uv[i1];
            Vector2 w2 = uv[i2];
            Vector2 w3 = uv[i3];

            float x1 = v2.x - v1.x;
            float x2 = v3.x - v1.x;
            float y1 = v2.y - v1.y;
            float y2 = v3.y - v1.y;
            float z1 = v2.z - v1.z;
            float z2 = v3.z - v1.z;

            float s1 = w2.x - w1.x;
            float s2 = w3.x - w1.x;
            float t1 = w2.y - w1.y;
            float t2 = w3.y - w1.y;

            float div = s1 * t2 - s2 * t1;
            float r = div == 0.0f ? 0.0f : 1.0f / div;

            Vector3 sdir = new Vector3((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
            Vector3 tdir = new Vector3((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);

            tan1[i1] += sdir;
            tan1[i2] += sdir;
            tan1[i3] += sdir;

            tan2[i1] += tdir;
            tan2[i2] += tdir;
            tan2[i3] += tdir;
        }


        for (long a = 0; a < vertexCount; ++a)
        {
            Vector3 n = normals[a];
            Vector3 t = tan1[a];

            //Vector3 tmp = (t - n * Vector3.Dot(n, t)).normalized;
            //tangents[a] = new Vector4(tmp.x, tmp.y, tmp.z);
            Vector3.OrthoNormalize(ref n, ref t);
            tangents[a].x = t.x;
            tangents[a].y = t.y;
            tangents[a].z = t.z;

            tangents[a].w = (Vector3.Dot(Vector3.Cross(n, t), tan2[a]) < 0.0f) ? -1.0f : 1.0f;
        }

        mesh.tangents = tangents;
    }
}
