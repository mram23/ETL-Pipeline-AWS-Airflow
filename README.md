# ETL-Pipeline-AWS-Airflow
En el mundo empresarial actual, la clave está en transformar datos en acciones. Imaginemos un escenario donde la información fluye desde múltiples fuentes, se procesa en un ecosistema dinámico y se entrega a toda la organización para su fácil consumo. Esto requiere de una orquestación de datos cuidadosa.

# Introducción

Automatizar == Orquestar / Organizar. El uso de Airflow nos va a ayudar a automatizar este proceso (ETL). Esto significa que incluso mientras tú duermes, Airflow se encarga. Airflow va a orquestar la extracción, la transformación y la carga en función de la hora a la que lo haya programado. Digamos que lo has programado para todos los días a las 12 pm, y eso se va a ejecutar.

Así que será bueno para nosotros entender los conceptos básicos de Apache Airflow. ¿Qué es Apache Airflow?

Apache Airflow es una plataforma de código abierto que se utiliza para orquestar y programar flujos de trabajo de tareas y pipelines de datos. ¿Qué queremos decir con esto? 

Tú puedes tener una serie de flujos de trabajo en su pipeline. Tomemos por ejemplo que usted está haciendo alguna extracción de una base de datos Postgres o que está extrayendo de la API. Esta es una tarea de aquí, y luego de eso, cuando usted consigue sus datos, que desea hacer alguna transformación ya sea una transformación simple o una transformación compleja, y luego los datos que tiene, que desea cargar tal vez como un archivo .csv o como un archivo de parquet en su cubo de Amazon S3, o cualquier plataforma que desea cargarlo. Este es su flujo de trabajo:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6154bcee-5a6f-4e77-a03e-ccd42a021302)

Es decir, Airflow proporciona una forma de crear, programar y monitorizar flujos de trabajo mediante programación. Esto significa que usted puede comprobar sus registros y averiguar cuál era el problema, entonces usted puede arreglarlo. Y así puedes seguir ejecutando su flujo de trabajo. 

Un concepto que realmente necesitamos entender en términos de Apache Airflow es lo que llamamos DAG. ¿Qué es **DAG**?

DAG significa Directed Acyclic Graph. Representa una colección de **tareas** y sus dependencias.

Podemos ver que cada nodo representa una tarea, por lo que el DAG está formado por nodos y flechas dirigidas / dependencias. Podemos ver, por ejemplo, cuando el Nodo 1 se completa, entonces va al Nodo 2. Desde el Nodo 2 va al Nodo 4, ¿verdad? Pero el Nodo 4 no se ejecutará si el Nodo 3 no se ejecutó. Como puedes ver el Nodo 2 y el Nodo 3 van al Nodo 4. Así que el Nodo 3 y el Nodo 2 necesitan ejecutarse antes de que el Nodo 4 se ejecute. Y el Nodo 4 necesita ejecutarse, antes de que el Nodo 5 se ejecute.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/79873c06-ab83-42d8-acc4-ad6c54e554bf)

Y un DAG define el orden en que deben ejecutarse estas tareas (nodos) y las dependencias entre ellas. Pero, ¿qué significa que un DAG sea acíclico? Significa que cuando se está en el Nodo 5, no se puede volver al Nodo 4. O el Nodo 5 va al Nodo 2 o al Nodo 3. Eso no puede suceder. No es así como funciona un DAG, es **acíclico**, no es un ciclo. Así que va en una sola dirección.

Ahora, echemos un vistazo a lo que son los **Operadores**.

Esas tareas de las que hablamos en el DAG, son básicamente operadores. Y hay diferentes tipos de operadores. Uno de ellos es un operador python, otro es un operador sensor.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/c7af9f3a-2e6d-4f93-8d7e-ec11b40fa55e)

Por ejemplo, la Tarea 1, es un operador python que te ayuda a ejecutar una función python que extrae datos de la API o quizás de una base de datos. También podría haber un operador python que te ayude a ejecutar una función que realice alguna transformación en tus datos.

# Manos a la obra

## De qué trata este proyecto

Hoy vamos a construir un proceso ETL completo que implica la conexión a Zillow RapidAPI donde vamos a extraer información de propiedades de bienes raíces. Y todo lo que vamos a hacer aquí va a ser en AWS Cloud. 

The workflow is:

Vamos a estar utilizando python para conectarse a la rápida API de Zillow y vamos a extraer los datos de que va a ser el Real State Properties información.

Y luego vamos a cargar esos datos en un cubo S3 que vamos a estar llamando una zona de aterrizaje. Inmediatamente obtenemos esos datos dentro del cubo de Amazon S3, que va a desencadenar una función Lambda que va a ayudar a copiar esta información de esta zona de aterrizaje en el cubo de la zona intermedia. ¿Y por qué estamos haciendo eso?

No queremos que nadie manipule esta información o estos datos en esta Zona de Aterrizaje. Así que queremos que cualquier otra conexión sea con este bucket de la Zona Intermedia. Queremos que la Zona de Aterrizaje sea lo más prístina posible. Eso también va a desencadenar otra función Lambda que luego transforma los datos, va a hacer algunos transformatio. Después de lo cual va a cargar los datos en el interior del cubo de datos transformados.

Luego podemos cargar los datos transformados dentro de un clúster de Amazon Redshift, que vamos a aprovisionar. Ahora, en ese punto podemos conectar una herramienta de BI.

Entonces, algo así será nuestro DAG

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/3bec8540-84a7-4090-9752-056b362b9acc)

Va a haber un operador python que se va a conectar a la RapidAPI de Zillow, que va a extraer los datos a nuestra Instancia EC2.

Después de lo cual vamos a tener un operador bash que va a mover los datos de nuestro EC2 en el cubo de Amazon S3 (Zona de aterrizaje)

Ahora, antes de que seamos capaces de cargar en Redshift, queremos asegurarnos de que nuestros datos ya están en el cubo de datos transformados. Y lo que nos va a ayudar a hacerlo es este S3KeySensor, que va a detectar si nuestros datos transformados están ahora en este bucket (Transformed data)

Luego, podemos tener otra tarea que implicará la carga de los datos en Redshift. Y eso va a completar esta tarea. Finalmente, podemos utilizar Power BI para visualizar nuestros datos.

## Empecemos

Lo primero que vamos a hacer es crear un Grupo. ¿Por qué? En la industria por lo general no va a utilizar su usuario root para ejecutar / crear proyectos. Vamos a asignar usuarios a grupos. Esto lo hacemos en IAM: 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ceee8161-1b02-4ca7-a762-b8e3a4a95963)

Después de crear ese grupo, lo siguiente que queremos hacer es crear usuarios.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/9d1a3bf2-445f-47c0-b6d0-eb07f311ed00)

Este usuario ahora va a tener acceso administrativo, porque tiene las políticas del grupo adjuntas.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/1748c001-0a9c-472c-a617-b7a8a880dde6)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4c0b9808-4663-49ba-9729-a64b29298b3b)

Vamos a crear la clave de acceso y la clave de acceso secreta para este usuario en particular

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/08fab3e8-0dce-4d61-8e75-8ec08ca451e8)

Luego, nos logeamos con nuestro usuario creado 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/df6fbe91-4367-4732-82f2-c71df6436274)

OJO: Vamos a trabajar todo en la región Oregon (us-west-2)

## Ahora ya estamos listos siguiendo los lineamiento de proyectos reales (industria)

Ahora procedemos a crear una instancia EC2. Porque ahí es donde vamos a instalar nuestro flujo de aire y vamos a tener nuestro desarrollo.  

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/cd369537-7bc7-4d08-94b6-0486f49a7e33)

Es recomendable usar el tipo de instancia t2.medium para evitar freezings y lageos.

Asimismo, para poder conectarnos a la máquina virtual via SSH, necesitamos de un key pair. OJO: Es necesario que sea .pem, con el fin de que puedas hacer la conexión de visual studio code a la instancia via Remote SSH

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/9e69f6e0-96fb-4406-9a32-da7b433b94ad)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ebbb8c0c-f8b7-448d-b993-f7777729e935)

Luego, con respecto a la configuración de Networking, personalizaremos nuestro grupo de seguridad de la instancia: 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/19197700-4a3b-4a57-a364-5c474560a82d)

Y luego, todas las demás configuraciones las mantenemos en su default y lanzamos la instancia:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/b3c523b8-223b-4ff1-85e3-7140e3935e3c)

Una vez que tenemos nuestra instancia lista. Lo siguiente que queremos hacer es empezar a instalar dependencias. Para ello, nos conectamos a nuestra instancia a través de EC2 Instance Connect

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e1106439-537e-4231-b9f6-1bfbc864fa65)

Donde nos abrirá un terminal, donde empezaremos a instalar las dependencias / paquetes necesarios para realizar este proyecto. 

Lo primero es correr el siguiente comando para hacer las actualizaciones respectivas a nuestra instancia. 

```bash
sudo apt update
sudo apt upgrade
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/fcacbf11-44ab-4bfe-bf6e-bdd4ebff803a)

Ahora instalamos *pip*

```bash
sudo apt install python3-pip
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/bc5d3660-3e71-4e0c-8b9a-115320c94ffd)
Luego, lo que haremos es instalar un virtual environment

```bash
sudo apt install python3.10-venv
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/1757eb46-e202-4def-af84-f507cbad46dd)

Ahora, procedemos a crear nuestro virtual environmet, donde instalaremos otras dependencias:

```bash
python3 -m venv restartproject_venv
```

Luego, activamos el venv

```bash
source restartproject_venv/bin/activate
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/30f0cd77-9c1c-471c-b948-4a70d79eba72)

Ahora vamos instalar la AWS CLI:

```bash
pip install --upgrade awscli
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/c6f86920-91de-4acd-a894-ff8b1fca6144)

Y también necesitamos instalar airflow:

```bash
sudo pip install apache-airflow
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6301c422-42f1-490f-ae5b-846925b52496)

Una vez instalado Apache Airflow, procedemos a levantarlo:

```bash
airflow standalone
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e2b28176-691d-415f-9c42-c6e681445016)

Ahora vamos a a interfaz de Airflow:

Al momento de ingresar 35.161.95.109:8080, notamos que no podemos conectarnos

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/603b23bb-0b74-4b78-bb0b-3b32be903c17)

Esto se debe a que no hemos abierto el puerto 8080 que permita la conexión de airflow hacia nuestra máquina virtual. Por lo que necesitamos modificar las reglas de entrada de nuestro grupo de seguridad:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/2c631ff8-7681-4215-8a90-ee97d2744709)

Ahora sí tenemos acceso:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/072197cb-9227-4274-b675-541a80371c08)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a31a24f6-3873-4e8b-84bf-2d88cc0c3b3e)

Lo siguiente que me gustaría hacer es conectar nuestro Visual Studio Code a nuestra Instancia EC2 para que podamos empezar a hacer que las cosas sucedan. 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/096868b4-619a-456b-94b9-c48200fe98bb)

Le debemos dar click a la parte baja esquina izquierda

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f45d251c-edae-42af-b37e-93633d43be5c)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/7d012f36-6bda-4388-9631-b46c8ed4feb5)

Vamos a Add New SSH Host

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ae8cf4bc-1667-4bcd-9d49-1f3b8a7d900a)

Previamente en el terminal, en el directorio donde se encuentra nuestro keypair debemos correr el siguiente comando: chmod 400 "restart-project-keypair.pem”

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/9bd6a297-206f-4fd1-a9b9-f2a4a36b9479)

```bash
icacls restart-project-keypair.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/12fcd18a-606f-4e3b-8a40-116dcf1a071d)

Y agregamos el SSH Connection Comand

```bash
ssh -i "D:\24-0\LabsReStart\reStartProject\restart-project-keypair.pem" ubuntu@ec2-35-161-95-109.us-west-2.compute.amazonaws.com
```

Y le damos ENTER, después de ello ya nos conectamos, ojo que entre las comillas debes colocar el path del archivo de la keypair

Como vemos en el archivo airflow.cfg que todo los flujos de trabajo que maneja airflow vivirán en la siguiente carpeta:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/32fd2c97-aac2-4609-ad14-879a203e3311)

Es necesario crear la subcarpeta *dags*:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e785591f-a983-4504-a877-e0590ae5f465)

Luego, creamos nuestro archivo de python llamado zillowanalytics.py

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/2011e0c5-9872-45f7-9893-5f40bb267af0)

Ahora, si quieres que no te aparezcan los ejemplos en tu airflow a la hora de levantarlo, lo que debemos hacer es colocar en False la clave *load_examples*

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ef61db78-2425-4f5b-acd6-41624a01346a)

**Nota.** Cada vez que actualice algo en su archivo airflow.cfg, deberá reiniciar el servidor airflow (en este caso se encuentra desplegado en nuestra máquina virtual) 

Entonces, en nuestra conexión de EC2 Instance Connect, en el terminal haremos CTRL+C (bajarnos airflow), y luego volver a levantarlo

```bash
airflow standalone
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/3ced4ce7-28ac-4afa-831d-49a6efaba813)

Una vez reseteado el airflow, vemos como la modificacion en el archivo de configuración se hace efectiva, ya no hay más ejemplos de dags:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a6df46de-5b12-4396-ba3d-2e0b5c71e379)

Creamos una cuenta en RapidAPI: https://rapidapi.com/hub

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f2e2f995-a9ab-49ec-9a6e-9079b91d98ef)

Voy a utilizar los datos que Rapid API me ha proporcionado como parte del conjunto de datos de Zillow. Sin embargo, parece que los datos no es un dato real de Zillow, pero sirve con fines académicos.

Entonces tenemos que suscribirse a nuestra API en particular que vamos a utilizar

https://rapidapi.com/s.mahmoud97/api/zillow56

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6487bcf7-ff21-4922-bea6-ff6075a76d3c)

Ahora, para conectarnos a extraer datos, necesitamos esta urlAhora, para conectarnos a extraer datos, necesitamos esta url:
`https://zillow56.p.rapidapi.com/search`

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/c140c7b0-05cb-482d-80a2-12629dccdfd4)

Ahora vamos a crear nuestra primera tarea: Conectarnos a la API de Zillow Rapid y extraer los datos

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/7110a24d-82bf-4726-b70f-1f3396c19a58)

Lo creamos con el siguiente dag_id: zillow_analytics_dag

Tenemos nuestros default args y empezamos creando nuestro primer task que es un python operator dentro de nuestro DAG:

```python
from airflow import DAG
from datetime import timedelta, datetime
import json
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 8, 1),
    'email': ['myemail@domain.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(seconds=15)
}

with DAG('zillow_analytics_dag',
        default_args=default_args,
        schedule_interval = '@daily',
        catchup=False) as dag:
				
				#python_callable represents the function that the python operator gonna run/execute
        extract_zillow_data_var = PythonOperator(
        task_id= 'tsk_extract_zillow_data_var',
        python_callable=extract_zillow_data,
        op_kwargs={'url': 'https://zillow56.p.rapidapi.com/search', 'querystring': {"location":"houston, tx"}, 'headers': api_host_key, 'date_string':dt_now_string}
        )
```

A continuación, dentro de esta carpeta de airflow, vamos a crear un archivo Json, donde copiaré la información del Endopoint, necesario para conectarnos a la API

```python
{
"X-RapidAPI-Key": "dec1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
"X-RapidAPI-Host": "zillow56.p.rapidapi.com"
}

```

Y estos datos son leídos en nuestro archivo zillowanalytics.py

```python
# Load JSON config file
with open('/home/ubuntu/airflow/config_api.json', 'r') as config_file:
    api_host_key = json.load(config_file)
```

Los parámetros necesarios para obtener un rpta de la API: url, headers and querystring

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/c11c7062-1394-4895-9a2b-e9827ff42376)

Ahora, veremos la función que nos permite conectarnos a la API y extraer la data:

```python
# We are using KeyWord args
def extract_zillow_data(**kwargs):
    url = kwargs['url']
    headers = kwargs['headers']
    querystring = kwargs['querystring']
    dt_string = kwargs['date_string']
    # return headers
    response = requests.get(url, headers=headers, params=querystring)
    response_data = response.json()
    

    # Specify the output file path
    output_file_path = f"/home/ubuntu/response_data_{dt_string}.json"
    file_str = f'response_data_{dt_string}.csv'

    # Write the JSON response to a file
    with open(output_file_path, "w") as output_file:
        json.dump(response_data, output_file, indent=4)  # indent for pretty formatting
    output_list = [output_file_path, file_str]
    return output_list   
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f903ec50-646b-48ce-b636-c93080e7157e)

OJO. 

```python
# Specify the output file path
now = datetime.now()
dt_now_string = now.strftime("%d%m%Y%H%M%S")
```

Guardamos, y vamos a ver si podemos ver este DAG en la interfaz de usuario de airflow, y sí después de unos minutos podemos verlo

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/c12421ed-0aa4-4cf5-bfcc-7890f5612416)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/b1ba26dd-a810-4002-8352-a6f24166035d)

Activemos nuestro DAG

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/9bfdc06b-01b8-4bad-b54b-63dc68667708)

Y si vemos que falla, y para comprobar dónde está el error en Logs:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/524b61d3-bb34-44e8-bf72-16d3fa398030)

Necesitamos importar *requests*. Para probarlo de nuevo, lo que tenemos que hacer es *Clear task*, y lo volverá a correr.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/1e06b7af-19f8-45bd-a590-42142937caf6)

Y funciona:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e4c7618f-0fa1-499c-a370-2c4ce6a5f151)

Y vemos el archivo resultante con la data *response_data_11032024142734.json*

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e7299153-4aad-4ad0-b8a7-4256394c5324)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/b389aef9-b579-4c3a-8c71-c24577e95317)

Creo que esto sólo se puede utilizar para una ciudad a la vez. Así que hemos validar que nuestra primera tarea se ejecute correctamente. Ahora, ¿Cómo podemos mover estos datos a nuestro cubo S3 *zona de aterrizaje*?

Vamos a crear la segunda tarea que va a ser un operador bash y lo que va a hacer es que en el momento en que este archivo (*response_data_xxxxx.json*) se crea, queremos utilizar la segunda tarea para mover este archivo desde nuestra Instancia EC2 al bucket S3.

En primer lugar, tenemos que crear nuestro cubo:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/43f5e97f-bb0f-484b-b180-4262ddce59b6)

Y dejamos lo demás como en default.

```python
load_to_s3 = BashOperator(
    task_id = 'tsk_load_to_s3',
    # We use the AWS CLI, mv -> move
    bash_command = 'aws s3 mv {{ ti.xcom_pull("tsk_extract_zillow_data_var")[0]}} s3://restart-project-bucket/',
)
```

ti → task instance

xcom → cross communication

so ti.xcom_pull → Quiero recuperar los datos que los resultados de la tarea anterior. Y sabemos que la tarea devuelve el output_list. 

ti.xcom_pull("tsk_extract_zillow_data_var")[0] →  Estoy recibiendo la ruta absoluta del archivo response_data_xxxx.json

**Nota.**  Necesitamos dar acceso a la Instancia EC2, creando un rol IAM para dar acceso entre servicios

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4de456c8-d163-432c-92ce-8267ca5c9d49)

And the policy gonna be *AmazonS3FullAccess*. 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a636942b-a27a-45d1-9f24-424a5b76c934)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/678dcd33-423d-4ee7-afbd-81e819328ba7)

Ahora adjuntamos dicho rol a nuestra instancia:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/294cc35e-8af1-471a-a36d-72be002ae8ca)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/1392568b-f517-454c-af50-7ccf2f80f392)

Ahora, no nos olvidemos de señalar las dependencias entre los tasks:

```python
# Dependencies
extract_zillow_data_var >> load_to_s3
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/8f766b3e-6f85-4035-bbfb-f1137a2ed458)

Entonces, ahora que trigguemos nuestro DAG, debemos ver nuestro json file inside our S3 bucket. 

**Nota.** Aquí experimenté un pequeño percance, pues me salía un error que me decía que no reconocía el comando bash. Luego, averiguando, como yo resetee el servidor de airflow, no estoy seguro pero había un error con la ubicación de aws. Por lo que para hallar su path corrí los siguientes comandos en el terminal:

```python
sudo apt-get update
sudo apt-get install awscli
aws --version
which aws
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e515c270-46ed-4a79-ba37-933572a73968)

Entonces, modifiqué el comando 

```python
bash_command = '/usr/bin/aws s3 mv {{ ti.xcom_pull("tsk_extract_zillow_data_var")[0]}} s3://restart-project-bucket/'
```

Y así logré ejecutar el DAG correctamente:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/aeb4ce97-fdcc-4962-83ca-19eed798722c)

Y se almacenó correctamente en el bucket:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/453e3ab6-ebd8-4c1e-8045-ea1f7b936ef7)

Ahora, al cargar los datos de restart-project-bucket (*zona de aterrizaje*) en el bucket *zona intermedia*, se activará una función lambda que copiará y cargará esos mismos datos json de *zona de aterrizaje* a *zona intermedia*, antes de que podamos hacer la transformación. Así que esta función lambda tendrá una copia en bruto del bucket de *zona de aterrizaje*. Entonces, creemos nuestra función Lambda:

Y sobre los roles, necesitamos crear uno nuevo para que Lambda tenga acceso a S3:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/aeaa106e-56f7-4ff2-af5f-acf4ca801d18)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/edc3df99-fee9-477b-8e8c-1753575fdffa)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/75d16e27-17e2-490d-9e9e-f12b012bc1d5)

El AWSLambdaBasicExecutionRole nos permite acceder a los CloudWatch Logs con fines de monitoreo. Creamos la función Lambda:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/2047eb18-8f87-4376-aed9-3a613e689bab)

A continuación, tenemos que añadir un disparador. Cuando nuestros datos lleguen a esta Zona de Aterrizaje queremos que dispare esta Función Lambda (rawCopyJsonFile-lambdaFunction). Y que incluso es cada vez que se carga un archivo

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4c2d25a6-a427-4a2f-b83a-b293ded78654)

Recuerda que tanto *json* y *boto3* están instalados en el entorno de Lambda, por lo que no es necesario añadir algún Layer adicional. A continuación, se muestra el código de la función lambda:

```python
import boto3
import json

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # TODO implement
    # Con el parametro event, recuperamos toda la info
    # de nuestro evento que usamos como trigger de la funcion
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
   
    
    target_bucket = 'restart-project-copy-raw-json-bucket'
    copy_source = {'Bucket': source_bucket, 'Key': object_key}
   
    waiter = s3_client.get_waiter('object_exists')
    waiter.wait(Bucket=source_bucket, Key=object_key)
    s3_client.copy_object(Bucket=target_bucket, Key=object_key, CopySource=copy_source)
    return {
        'statusCode': 200,
        'body': json.dumps('Copy completed successfully')
    }
```

**OJO.** En el caso aparezca este error, significa que quieres usar el mismo evento como trigger en más de una función, eso no se puede. Por lo que debes ir al bucket y en la sección de properties → events, remover dicho evento

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e5ea1dfe-85a0-48c0-ae88-8ec9f35746a6)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6ea6208a-4c25-4445-8eb6-77e5640a8234)

Después de guardar (Deploy) nuestra función, necesitamos crear nuestro bucket de destino, donde irá la copia

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/29f4ceaa-729d-4dc9-9428-6405f50f655e)

La copia es de *restart-project-bucket* a *restart-project-copy-raw-json-bucket*.

Así que ahora cuando vuelva a ejecutar airflow, se subirá un nuevo archivo .json al bucket de landing zone (restart-project-bucket), lo que disparará la función lambda que copiará estos datos en el bucket intermedio

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/bad666b3-c404-490d-9fab-f1fdc0ef4e26)

Y vemos que el nuevo archivo subido al Landing zone bucket se copia al *restart-project-copy-raw-json-bucket*

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/47ee8065-50e9-48a7-a9e8-f95f7b6d9638)

Y ahora procedemos a crear la otra función lambda que se activará cuando detecte nuevos archivos en el bucket *restart-project-copy-raw-json-bucket*, nos permitirá hacer las transformaciones respectivas a la data:

![FlujoDeTrabajo](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a7a002bc-df16-4c77-a53a-0f22da0af247)

Entonces, creamos dicha función:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/0235fa0b-9867-4dfd-a0ec-fcf3d208145c)

Y configuramos nuestro disparador del que hemos hablado (Bucket de Zona Intermedia):

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/1ae52acb-9875-4836-80b9-bc57aaea8d81)

Esta es el código de la función:

```python
import boto3
import json
import pandas as pd

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # TODO implement
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    target_bucket = 'restart-project-cleaned-zone-bucket'
    # e.g: response_data_xxxxxxxxxxxxxxx
    target_file_name = object_key[:-5]
    # con el fin de verificar en CloudWatch Logs
    print(target_file_name)
   
    waiter = s3_client.get_waiter('object_exists')
    waiter.wait(Bucket=source_bucket, Key=object_key)
    
    response = s3_client.get_object(Bucket=source_bucket, Key=object_key)
    print(response)
    data = response['Body']
    print(data)
    data = response['Body'].read().decode('utf-8')
    print(data)
    data = json.loads(data)
    print(data)
    f = []
    for i in data["results"]:
        f.append(i)
    df = pd.DataFrame(f)
    # Select specific columns
    selected_columns = ['bathrooms', 'bedrooms', 'city', 'homeStatus', 
                    'homeType','livingArea','price', 'rentZestimate','zipcode']
    df = df[selected_columns]
    print(df)
    
    # Convert DataFrame to CSV format
    csv_data = df.to_csv(index=False)
    
    # Upload CSV to S3
    bucket_name = target_bucket
    object_key = f"{target_file_name}.csv"
    s3_client.put_object(Bucket=bucket_name, Key=object_key, Body=csv_data)
    
    
    return {
        'statusCode': 200,
        'body': json.dumps('CSV conversion and S3 upload completed successfully')
    }
```

Por ello, necesitamos crear el bucket objetivo, hacia donde se dirigirá la data transformada resultante 

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/d171170c-42cd-4428-81a5-c7579b322478)

Después de que guardemos (deploy) el código de nuestra función, volvamos a correr nuestro DAG en airflow. Pero antes podemos crear la tercera tarea que nos ayudará a monitorizar el restart-project-cleaned-zone-bucket si ya tenemos el archivo .csv dentro o no. Necesitamos instalar el proveedor Amazon Apache Airflow

```python
# for the new task
is_file_in_s3_available = S3KeySensor(
task_id='tsk_is_file_in_s3_available',
bucket_key='{{ti.xcom_pull("tsk_extract_zillow_data_var")[1]}}',
bucket_name=s3_bucket,
aws_conn_id='aws_s3_conn',
wildcard_match=False,  # Set this to True if you want to use wildcards in the prefix
timeout=60,  # Optional: Timeout for the sensor (in seconds)
poke_interval=5,  # Optional: Time interval between S3 checks (in seconds)
)
```

Y para instalar el proveedor de Amazon para Apache Airflow

```bash
pip install apache-airflow-providers-amazon 
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/74351204-ec63-436d-85b6-5e84b91548bc)

Después de agregar el nuevo task y su respectiva dependenica, lo conveniente es reiniciar el servidor. **Nota.** Para esta tarea necesitamos dar acceso a Airflow a nuestro bucket S3

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/cc90b843-3172-4ccc-a745-32d61ea93cf3)

Creamos la conexión, que permitirá a Airflow acceder a los servicios de AWS

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/f778913a-8c84-4491-88d3-2311027019c5/Untitled.png)

Bien, una vez establecida la conexión, procedemos a probar nuestro flujo con airflow, y obtenemos un error: Vemos que sí logra recuperar la conexión, sin embargo mientras espera que aparezca el archivo .csv, sobrepasa el límite de 60sec.

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/423610e9-8e87-4591-a12f-ce398b4f511b)

Y bueno el problema está en que la función lambda *transformation-json-to-csv-lambdFunction*, no se está ejecutando correctamente. Esto lo notamos en los ClaudWatch Logs. Donde vemos el siguiente mensaje:

```
[ERROR] Runtime.ImportModuleError: Unable to import module 'lambda_function': No module named 'pandas'
Traceback (most recent call last):
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/8478e815-e773-47af-a8bb-58707d1890f5)

Para solucionar este problema, lo que debemos hacer es añadir un Layer (*capa*) a la función

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ce68d668-3ce1-4b7d-bc50-8895df44cb0e)

Y vemos que el DAG se ejecutó correctamente:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4be7d76b-4800-45cb-843a-c96ebbe4d25b)

Notamos que nuestro task *tsk_is_file_in_s3_available* fue un éxito debido a que logró identificar el archivo .csv en el bucket *restart-project-cleaned-zone-bucket*. Como resultado de la función que tenía como target dejar la data transformada en este bucket

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/5e50aae5-a3b3-4cd6-b68c-f3aa118cd16e)

la razón por la que necesitamos tener un sensor antes de añadir el *Operador Redshift*, porque si eres el operador Redshift aquí sin el sensor, eso significa que no tendrás la visibilidad al archivo en tu S3. Usted no sabe si está allí o no. 

Hasta ahora hemos trabajado en la extracción de datos de la ZillowAPI RapidAPI, cargamos eso en nuestro primer cubo S3 que llamamos la Zona de Aterrizaje, y eso desencadenó una Función Lambda que luego copia ese archivo json en otro cubo (Zona intermedia). Inmediatamente aterriza en este cubo, desencadena otra función lambda que hace algunas transformaciones, seleccionamos algunas columnas de los datos y luego convertimos los datos en CSV. Y luego lo cargamos en el cubo de la Zona Limpia. Ahora, lo que queremos hacer, queremos cargar los datos dentro de Redshift y luego usar PowerBI para visualizar algunos de esos datos. Hemos estado usando airflow para orquestar este proceso. Usamos S3KeySensor para detectar que el archivo .csv ya existe en el bucket Cleaned Zone

Así que ahora, vamos a crear nuestro cluster Redshift

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ee4f72f7-1285-42f9-9c6b-209a74e5fc8d)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/e1bd73ae-b2fe-4002-94c9-d1ef4225ba5e)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/eb807d41-ba3a-4063-8ac7-a7037a86c392)

Luego, vamos a nuestro query editor v2: Para conectarnos al data warehouse

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f527a086-d552-4366-814a-96f7a8fe51c6)

Donde podremos crear nuestra tabla:

```sql

CREATE TABLE IF NOT EXISTS zillowdata(bathrooms NUMERIC,
bedrooms NUMERIC, 
city VARCHAR(255), 
homeStatus VARCHAR(255),
homeType VARCHAR(255), 
livingArea NUMERIC,
price NUMERIC,
rentZestimate NUMERIC,
zipcode INT
)

SELECT * FROM zillowdata
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a7e18e25-d609-43c8-960f-074cd40b4e25)

Y vemos que aún no tiene registros

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/aeccc833-3f32-4a99-ac33-696142877187)

Para cargar la data a la tabla de nuestro Data Warehouse, usaremos un task:

```python
transfer_s3_to_redshift = S3ToRedshiftOperator(
task_id="tsk_transfer_s3_to_redshift",
# we need access to S3
aws_conn_id='aws_s3_conn',
redshift_conn_id='conn_id_redshift',
s3_bucket=s3_bucket,
s3_key='{{ti.xcom_pull("tsk_extract_zillow_data_var")[1]}}',
schema="PUBLIC",
table="zillowdata",
copy_options=["csv IGNOREHEADER 1"],
)
```

Necesitamos hacer la conexión de airflow a redshift:

Host <> Endpoint del Redshift hasta .com

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/38891ca5-0715-427e-8dc1-c558740e3991)

**OJO.** Es necesario que nuestro servidor de Airflow, como le estamos dando conexión con Redshift, la instancia donde está desplegado este server debe tener permisos que le den acceso a Redshift

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f1cddafa-d5f7-4302-b481-d20d919e6491)

También debemos modificar las reglas de entrada (security group) de nuestro Redshift cluster:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/2efb1877-1033-40db-94b1-211180729f5f)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6ea79b81-0f0a-4bf2-ab2c-4cbc866e97b3)

Vamos a correr nuestro DAG en la UI de airflow:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/d7f949c7-ca13-47d2-b511-f29c3d30f622)

Cuando lo ejecutamos debemos ser capaces de extraer los datos de la API a la zona de aterrizaje que desencadenan la función lambda y que copiará el archivo json en el cubo intermedio, que desencadena otra función lambda hacemos alguna transformación y también convertir a csv. Y que las cargas en la zona limpia cubo y luego tenemos un S3KeySensor que asegura que nuestros archivos está aquí. Si está allí, entonces se dispara el operador S3ToRedshift, que luego cargará el archivo .csv en Redshift

Fue un éxito

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4c5c1e48-cea0-4e0e-8399-927ad355073a)

Asimismo, vemos que ya se cargó data al Redshift:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ec4f8d0c-0964-4283-9880-5c63ac34c6b1)

Para reiniciar nuestro airflow (desplegado en nuestra instancia de EC2):

```bash
sudo pkill gunicorn
ps aux | grep gunicorn
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/30c19be2-a576-4694-8284-e71d8a15df1f)

```bash
airflow standalone
```

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/039a2712-bd39-46a2-86a9-ee748f657ed1)

Si volvemos a ejecutar el DAG, los datos se añaden

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/d27fb70e-8cd9-4786-a654-4a2e6afb749c)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/74da860c-897c-4e4c-953a-c414bfc1e8ea)

Podemos ver nuestro tamaño de almacenamiento

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/a9652211-ef26-4229-9b56-8c8755b43599)

```sql
-- Para crear la tabla zillowdata
CREATE TABLE IF NOT EXISTS zillowdata(bathrooms NUMERIC,
bedrooms NUMERIC, 
city VARCHAR(255), 
homeStatus VARCHAR(255),
homeType VARCHAR(255), 
livingArea NUMERIC,
price NUMERIC,
rentZestimate NUMERIC,
zipcode INT
);

-- Para visualizar toda la tabla
SELECT * FROM zillowdata;

-- Para tener un conteo de los registros cargados
SELECT COUNT(*) FROM zillowdata;

-- Para ver un promedio de costos de la propiedades según la ciudad
SELECT city, COUNT(*) AS num_properties, AVG(price) AS avg_price
FROM zillowdata
GROUP BY city;

-- Ordenamos las propiedades en venta por el precio de mayor a menor
SELECT * FROM zillowdata
WHERE homeStatus = 'FOR_SALE'
ORDER BY price DESC;

-- Para ver propiedades en venta dentro de un rango de precio
SELECT *FROM zillowdata
WHERE homeStatus = 'FOR_SALE'
  AND price BETWEEN 500000 AND 1000000
  AND city = 'Houston';

-- Vemos algunas datos estadísticos del número de cuartos, se hace la evaluación según cada cantidad de cuarto
-- Aquí podemos notar la diferencia de precio entre ciudades
SELECT bedrooms, city,
    COUNT(*) AS num_properties,
    AVG(price) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM zillowdata
WHERE city IN ('Houston', 'Miami')
GROUP BY bedrooms, city
ORDER BY bedrooms, city;

-- Para obtener el tamaño total del almacenamiento utilizado por todas las tablas en el esquema público
SELECT SUM(size) AS total_size
FROM SVV_TABLE_INFO
WHERE schema = 'public';
```

Finalmente, procedemos a conectar Redshift a PowerBI:

Para ello, primero debemos hacer accesible al público nuestro cluster

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/4ddd5ba5-3f6b-43fb-b606-0dcd24c730a9)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/096ee218-34d0-4f18-9e67-0977177eb278)

Y en PowerBI obtenemos los datos:

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/ea28c315-78ba-4bcc-9a19-d9417d4d2994)

Server: [redshift-cluster-1.cfviphrlqe05.us-west-2.redshift.amazonaws.com:5439](http://redshift-cluster-1.cfviphrlqe05.us-west-2.redshift.amazonaws.com:5439/dev)

Database: dev

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/47f58dfa-a63f-4772-a068-d4cd975107fb)
![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/f8092821-0a28-49b0-bc3f-3ad5cf050549)

Y nos conectamos

![image](https://github.com/mram23/ETL-Pipeline-AWS-Airflow/assets/132526921/6846d90f-525b-4e88-9107-f665b5df519e)
