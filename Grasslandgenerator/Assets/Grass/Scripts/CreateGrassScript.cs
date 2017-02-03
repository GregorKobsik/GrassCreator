using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CreateGrassScript: MonoBehaviour
{

    

    public Material grassBillboardMaterial;
    public Material grassGeometryMaterial;
    public Texture2D heightmap;
    private float heightmap_coeffizient = 50;
    public Slider heightmap_slider;
    public Transform transObject;
    public Transform sunPos;
    public Transform cameraPos;

    public float far = 25;
    public float near = 0;
    

    private Transform goTrans;
    private Vector3 oldPos;
    private float oldNear;
    private float oldFar;


    private GameObject billboardGo;
    private GameObject geometryGo;
    private MeshFilter billboardMf;
    private MeshFilter geometryMf;
    private MeshRenderer billboardMr;
    private MeshRenderer geometryMr;
    private Mesh billboardMesh;
    private Mesh geometryMesh;

    public void Start()
    {
        goTrans = transObject;

        billboardGo = new GameObject();
        billboardGo.transform.parent = gameObject.transform;
        billboardMf = billboardGo.AddComponent<MeshFilter>();
        billboardMr = billboardGo.AddComponent<MeshRenderer>();

        billboardMr.material = grassBillboardMaterial;
        billboardMr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        billboardMesh = createTurfBillboard(heightmap, goTrans.position, near, far, heightmap_coeffizient);
        billboardMf.mesh = billboardMesh;

        geometryGo = new GameObject();
        geometryGo.transform.parent = gameObject.transform;
        geometryMf = geometryGo.AddComponent<MeshFilter>();
        geometryMr = geometryGo.AddComponent<MeshRenderer>();

        geometryMr.material = grassGeometryMaterial;
        geometryMr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
        geometryMesh = createTurfGeometry(heightmap, goTrans.position, near, far, heightmap_coeffizient);
        geometryMf.mesh = geometryMesh;

        

    }

    public void Update()
    {
        if (oldPos.x != goTrans.position.x|| oldPos.z != goTrans.position.z || oldFar != far || oldNear != near)
        {
            oldPos = goTrans.position;
            oldFar = far;
            oldNear = near;
            heightmap_coeffizient = 50;//heightmap_slider.value;
            
            //create new geometry Mesh
            Destroy(geometryMesh);
            geometryMesh = createTurfGeometry(heightmap,goTrans.position, near, far, heightmap_coeffizient);
            geometryMf.mesh = geometryMesh;

            //create new billboard Mesh
            Destroy(billboardMesh);
            billboardMesh = createTurfBillboard(heightmap, goTrans.position, near, far, heightmap_coeffizient);
            billboardMf.mesh = billboardMesh;

            //update Shader variables
            //grassBillboardMaterial.SetVector("_Center", new Vector4(oldPos.x, oldPos.y, oldPos.z, 0));
            //grassBillboardMaterial.SetFloat("_Heightmap_Coeffizient", heightmap_coeffizient);
            
 
        }
        
        //grassBillboardMaterial.SetVector("_LightPos", new Vector4(sunPos.rotation.x,sunPos.rotation.y,sunPos.rotation.z));
        //grassBillboardMaterial.SetVector("_CameraPos", new Vector4(cameraPos.position.x, cameraPos.position.y, cameraPos.position.z));

        //grassGeometryMaterial.SetVector("_LightPos", new Vector4(sunPos.rotation.x, sunPos.rotation.y, sunPos.rotation.z));
        //grassGeometryMaterial.SetVector("_CameraPos", new Vector4(cameraPos.position.x, cameraPos.position.y, cameraPos.position.z));

    }


    static Mesh createTurfBillboard(Texture2D heightmap, Vector3 position, float near = 0, float far = 25, float heightmap_coeffizient = 50)
    {

        Mesh mesh = new Mesh();

        const int GRASS_RANGE_HALF = Constants.GRASS_RANGE / 2;

        int width = heightmap.width;
        int height = heightmap.height;

        List<Vector3> myVertices = new List<Vector3>();
        List<Vector4> myTangents = new List<Vector4>();
        List<Vector2> myUV0 = new List<Vector2>();
        int[] myIndices;



        float posX = 0;
        float posY = 0;
        float posZ = 0;

        
        // create only GRASS_RANGE*GRASS_RANGE field around position //change algorithm to only a circle around player pos
        for (int z = 0; z < Constants.GRASS_RANGE; z++)
        {
            for (int x = 0; x < Constants.GRASS_RANGE; x++)
            {
                posX = (float) System.Math.Floor(position.x - GRASS_RANGE_HALF + 0.5f) + x;
                posZ = (float) System.Math.Floor(position.z - GRASS_RANGE_HALF + 0.5f) + z;
                //TODO: add Splatmap Dependencies
                float length = (z - GRASS_RANGE_HALF) * (z - GRASS_RANGE_HALF) + (x - GRASS_RANGE_HALF) * (x - GRASS_RANGE_HALF);
                if (length >= near*near && length <= far*far && length <= GRASS_RANGE_HALF * GRASS_RANGE_HALF && posX > 0 && posX < Constants.MESH_SIZE && posZ > 0 && posZ < Constants.MESH_SIZE)
                {
                    Random.InitState((int)(posX * posZ));
                    float RandX = (float)(Random.Range(0, 100) / 200.0f);
                    float RandZ = (float)(Random.Range(0, 100) / 200.0f);
                    posX += RandX;
                    posZ += RandZ;

                    Vector2 myUV = new Vector2((float)(posX / Constants.MESH_SIZE), (float)(posZ / Constants.MESH_SIZE));
                    myUV0.Add(myUV);         
                    posY = heightmap.GetPixel((int) (myUV.x * width) ,(int) (myUV.y * height)).grayscale * heightmap_coeffizient;                    
                    myVertices.Add(new Vector3(posX, posY, posZ));                   
                    myTangents.Add(new Vector4(
                        (float)(posX / Constants.MESH_SIZE),
                        (float)(posZ / Constants.MESH_SIZE),
                        (float)(Constants.MESH_SIZE),
                        (float)(Constants.MESH_SIZE)));
                }

            }
        }

        int numOfVertices = myVertices.Count;
        myIndices = new int[numOfVertices];
        for (int i = 0; i < numOfVertices; i++)
        {
            myIndices[i] = i;
        }

        mesh.SetVertices(myVertices);
        mesh.SetTangents(myTangents);
        mesh.SetUVs(0, myUV0);
        mesh.SetIndices(myIndices, MeshTopology.Points, 0);

        return mesh;
    }

    public static Mesh createTurfGeometry(Texture2D tex, Vector3 center, float near = 0, float far = 10, float heightmap_coefficient = 50, string name = "", int offset_x = 0, int offset_z = 0)
    {
        Mesh mesh = new Mesh();

        List<Vector3> myVertices = new List<Vector3>();
        List<int> myIndices = new List<int>();
        List<Vector2> myPosGlobal = new List<Vector2>();
        List<Vector2> myTexcoord = new List<Vector2>();

        int grassDensity = 4; //max 10 ??? 

        float posX = 0;
        float posZ = 0;
        float posY = 0;
        int counter = 0;
        //world space
        for (int worldX = 0; worldX < Constants.MESH_SIZE; worldX++)
        {
            for (int worldZ = 0; worldZ < Constants.MESH_SIZE; worldZ++)
            {
                
                //quad Within world space
                for (int x = 0; x< grassDensity; x++)
                {
                    for (int z = 0; z<grassDensity; z++)
                    {

                        posX = (worldX + (float)x / grassDensity);
                        posZ = (worldZ + (float)z / grassDensity);
                        float length = (posX - center.x) * (posX - center.x) + (posZ - center.z) * (posZ - center.z);
                        if ( length <= near * near && posX > 0 && posX < Constants.MESH_SIZE && posZ > 0 && posZ < Constants.MESH_SIZE && counter <= 65533)
                        {


                            posY = tex.GetPixel(    (int)(System.Math.Floor(posX / Constants.MESH_SIZE * tex.width)),
                                                    (int)(System.Math.Floor(posZ / Constants.MESH_SIZE * tex.height))).grayscale * heightmap_coefficient;

                            Vector2 globalPos = new Vector2(posX, posZ);

                            myVertices.Add(new Vector3(posX, posY, posZ));
                            myVertices.Add(new Vector3(posX, posY, posZ));
                            myPosGlobal.Add(globalPos);
                            myPosGlobal.Add(globalPos);
                            myTexcoord.Add(new Vector2(0,0));
                            myTexcoord.Add(new Vector2(1,0));
                            myIndices.Add(counter);
                            myIndices.Add(counter + 1);

                            counter += 2;
                        }
                    }
                }                

            }
        }

        mesh.SetVertices(myVertices);
        mesh.SetUVs(0, myPosGlobal);
        mesh.SetUVs(1, myTexcoord);
        mesh.SetIndices(myIndices.ToArray(), MeshTopology.Lines, 0, true);

        return mesh;
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
        float heightCoefficient = 1.0f;

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
