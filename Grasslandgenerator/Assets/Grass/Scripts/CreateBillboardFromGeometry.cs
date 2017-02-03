using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateBillboardFromGeometry : MonoBehaviour {

    private GameObject geometryGo;
    private MeshFilter geometryMf;
    private MeshRenderer geometryMr;
    private Mesh geometryMesh;

    public Material grassGeometryMaterial;

    // Use this for initialization
    void Start () {

        geometryGo = new GameObject();
        geometryGo.transform.parent = gameObject.transform;
        geometryMf = geometryGo.AddComponent<MeshFilter>();
        geometryMr = geometryGo.AddComponent<MeshRenderer>();

        geometryMr.material = grassGeometryMaterial;
        geometryMr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
        geometryMesh = createTurfGeometry();
        geometryMf.mesh = geometryMesh;
    }
	
	// Update is called once per frame
	void Update () {
		
	}


    public static Mesh createTurfGeometry()
    {
        GameObject go = new GameObject("Turf_");
        MeshFilter mf = go.AddComponent(typeof(MeshFilter)) as MeshFilter;

        GameObject bladeOfGrass = createBladeOfGrass();

        int grassDensity = 10; //max 10 ??? 

        float posX = 0;
        float posZ = 0;
        float posY = 0;
        int counter = 0;
        //world space
        for (int worldX = 1; worldX < 2; worldX++)
        {
            for (int worldZ = 1; worldZ < 2; worldZ++)
            {

                //quad Within world space
                for (int x = 0; x < 1; x++)
                {
                    for (int z = 0; z < grassDensity; z++)
                    {

                        posX = (worldX + (float)x / grassDensity);
                        posZ = (worldZ + (float)z / grassDensity);
                        if (true)
                        {
                            Random.InitState((int)(10*posX * 250*posZ));
                            float rand1 = (float)(Random.Range(0, 500) - 250) / 1000;
                            float rand2 = (float)(Random.Range(0, 500) - 250) / 1000;

                            posX += rand1;
                            posZ += rand2;
                            posY = 0;

                            //bladeOfGrass.transform.localScale = new Vector3(2,2,2);
                            GameObject newBladeOfGrass = Instantiate(bladeOfGrass, go.transform);
                            newBladeOfGrass.transform.localPosition = new Vector3(posX, posY, posZ);
                            newBladeOfGrass.transform.localRotation = new Quaternion(rand1, rand1 * rand2 * 100, rand2, 1);
                            //pass world coords to blade
                            List<Vector2> uv1 = new List<Vector2>();
                            for (int i = 0; i < 5; i++)
                                uv1.Add(new Vector2(posX, posZ));
                            newBladeOfGrass.GetComponent<MeshFilter>().mesh.SetUVs(1, uv1);

                            counter += 5;
                        }
                    }
                }

            }
        }

        mergeMeshes(go);

        Object.Destroy(bladeOfGrass);

        foreach (Transform child in go.transform)
        {
            GameObject.Destroy(child.gameObject);
        }

        Mesh mesh = mf.mesh;

        GameObject.Destroy(go);

        return mf.mesh;
    }


    public static GameObject createBladeOfGrass(Transform parent = null)
    {
        GameObject go = new GameObject("Blade Of Grass");
        if (parent != null)
        {
            go.transform.SetParent(parent);
        }
        go.transform.SetParent(parent);
        MeshFilter mf = go.AddComponent(typeof(MeshFilter)) as MeshFilter;

        Mesh m = new Mesh();

        float widthCoefficient = 0.7f;
        float heightCoefficient = 1.0f + Random.Range(0, 100) / 200f;

        Vector3[] myVertices =
        {
            new Vector3(widthCoefficient * 0.0f,   heightCoefficient * 0.0f,   0.0f), // 1
            new Vector3(widthCoefficient * 0.1f,   heightCoefficient * 0.0f,   0.0f), // 2
            new Vector3(widthCoefficient * 0.07f,  heightCoefficient * 0.8f,   0.0f), // 3
            new Vector3(widthCoefficient * 0.05f,  heightCoefficient * 1.0f,   0.0f), // 4
            new Vector3(widthCoefficient * 0.03f,  heightCoefficient * 0.8f,   0.0f)  // 5
        };

        Vector2[] myUV =
        {
            new Vector3(0.0f, myVertices[0].y),
            new Vector3(1.0f, myVertices[1].y),
            new Vector3(1.0f, myVertices[2].y),
            new Vector3(0.5f, myVertices[3].y),
            new Vector3(0.0f, myVertices[4].y)
        };

        int[] myTriangles =
        {
            0,1,4,2,4,1,4,2,3 //front face
            //make Backface in Shader, to complicated with nomals and such here.
        };



        m.vertices = myVertices;
        m.uv = myUV;
        m.triangles = myTriangles;


        mf.mesh = m;

        m.RecalculateBounds();
        m.RecalculateNormals();

        //do I need tangents? i think no, takes to much time

        return go;
    }




    static void mergeMeshes(GameObject go)
    {
        MeshFilter[] meshFilters = go.GetComponentsInChildren<MeshFilter>();
        CombineInstance[] combine = new CombineInstance[meshFilters.Length];
        int i = 0;
        while (i < meshFilters.Length)
        {
            combine[i].mesh = meshFilters[i].sharedMesh;
            combine[i].transform = meshFilters[i].transform.localToWorldMatrix;
            meshFilters[i].gameObject.SetActive(false);
            i++;
        }
        Destroy(go.transform.GetComponent<MeshFilter>().mesh);
        go.transform.GetComponent<MeshFilter>().mesh = new Mesh();
        go.transform.GetComponent<MeshFilter>().mesh.CombineMeshes(combine);
        go.transform.gameObject.SetActive(false);
    }
}



