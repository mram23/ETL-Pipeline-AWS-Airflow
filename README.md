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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/64d72072-a6aa-44a8-ab9f-ab752b482fa0/Untitled.png)

Es recomendable usar el tipo de instancia t2.medium para evitar freezings y lageos.

Asimismo, para poder conectarnos a la máquina virtual via SSH, necesitamos de un key pair. OJO: Es necesario que sea .pem, con el fin de que puedas hacer la conexión de visual studio code a la instancia via Remote SSH

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2f30fe64-3387-4a97-a0a6-b3e22ed766d7/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d616a517-19fb-4c52-9821-c74ecce38836/Untitled.png)

Luego, con respecto a la configuración de Networking, personalizaremos nuestro grupo de seguridad de la instancia: 

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/ab518c0c-c6bc-45f9-825a-ee792487a45d/Untitled.png)

Y luego, todas las demás configuraciones las mantenemos en su default y lanzamos la instancia:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/58ce21d4-f5c7-4113-92ff-deb899e28891/Untitled.png)

Una vez que tenemos nuestra instancia lista. Lo siguiente que queremos hacer es empezar a instalar dependencias. Para ello, nos conectamos a nuestra instancia a través de EC2 Instance Connect

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2b28f08c-a8e6-4965-bb02-6e0238923355/Untitled.png)

Donde nos abrirá un terminal, donde empezaremos a instalar las dependencias / paquetes necesarios para realizar este proyecto. 

Lo primero es correr el siguiente comando para hacer las actualizaciones respectivas a nuestra instancia. 

```bash
sudo apt update
sudo apt upgrade
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/74186906-b8cd-4cd1-9210-7295fe90e99d/Untitled.png)

Ahora instalamos *pip*

```bash
sudo apt install python3-pip
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2feee33e-8608-4294-ba99-70a7d066876d/Untitled.png)

Luego, lo que haremos es instalar un virtual environment

```bash
sudo apt install python3.10-venv
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/6956aae5-b84f-4282-95c1-c667b513fad6/Untitled.png)

Ahora, procedemos a crear nuestro virtual environmet, donde instalaremos otras dependencias:

```bash
python3 -m venv restartproject_venv
```

Luego, activamos el venv

```bash
source restartproject_venv/bin/activate
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/21c72a58-d7c8-4d7a-885c-a742f0db5588/Untitled.png)

Ahora vamos instalar la AWS CLI:

```bash
pip install --upgrade awscli
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/fa0b74ad-2c10-40c7-9adf-be20bc5eb85d/Untitled.png)

Y también necesitamos instalar airflow:

```bash
sudo pip install apache-airflow
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/bbb6c1ed-1500-49ab-88e3-181e420a4b21/Untitled.png)

Una vez instalado Apache Airflow, procedemos a levantarlo:

```bash
airflow standalone
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/3d61297a-f11e-4101-a394-d12e0fbefbc4/Untitled.png)

Ahora vamos a a interfaz de Airflow:

Al momento de ingresar 35.161.95.109:8080, notamos que no podemos conectarnos

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/42090261-a08d-4012-9a39-0dda88b3869a/Untitled.png)

Esto se debe a que no hemos abierto el puerto 8080 que permita la conexión de airflow hacia nuestra máquina virtual. Por lo que necesitamos modificar las reglas de entrada de nuestro grupo de seguridad:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/79399d0f-1543-4164-9a87-4721915d2c19/Untitled.png)

Ahora sí tenemos acceso:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/79d68647-eb09-40ed-bd91-6a2c8c976747/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/4bdb89e7-83ca-4dd0-baf9-40cf000aad1b/Untitled.png)

Lo siguiente que me gustaría hacer es conectar nuestro Visual Studio Code a nuestra Instancia EC2 para que podamos empezar a hacer que las cosas sucedan. 

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/64061f35-71c8-4c11-8e1d-62a5845bcf58/Untitled.png)

Le debemos dar click a la parte baja esquina izquierda

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/dd10cbfa-5640-489a-9614-970bb0566fdf/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/1b9246ed-5aac-4234-88f4-05d4637e07c0/Untitled.png)

Vamos a Add New SSH Host

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a1598a00-caf8-4005-9103-d20ee9b3d7a7/Untitled.png)

Previamente en el terminal, en el directorio donde se encuentra nuestro keypair debemos correr el siguiente comando: chmod 400 "restart-project-keypair.pem”

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d6bd20f9-5c32-4cf1-80fe-e7d1f0ed5512/Untitled.png)

```bash
icacls restart-project-keypair.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2a637785-bd24-42ae-8afb-5e319b7c388e/Untitled.png)

Y agregamos el SSH Connection Comand

```bash
ssh -i "D:\24-0\LabsReStart\reStartProject\restart-project-keypair.pem" ubuntu@ec2-35-161-95-109.us-west-2.compute.amazonaws.com
```

Y le damos ENTER, después de ello ya nos conectamos, ojo que entre las comillas debes colocar el path del archivo de la keypair

Como vemos en el archivo airflow.cfg que todo los flujos de trabajo que maneja airflow vivirán en la siguiente carpeta:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a22c18fa-b850-4de6-81e1-503659b46137/Untitled.png)

Es necesario crear la subcarpeta *dags*:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/019ce735-53e3-4912-8281-ef0a827eb06c/Untitled.png)

Luego, creamos nuestro archivo de python llamado zillowanalytics.py

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/7728542b-9f4b-4228-8cb6-20f03cd32907/Untitled.png)

Ahora, si quieres que no te aparezcan los ejemplos en tu airflow a la hora de levantarlo, lo que debemos hacer es colocar en False la clave *load_examples*

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/6fa5feec-567e-489c-af71-2472b2942b3f/Untitled.png)

**Nota.** Cada vez que actualice algo en su archivo airflow.cfg, deberá reiniciar el servidor airflow (en este caso se encuentra desplegado en nuestra máquina virtual) 

Entonces, en nuestra conexión de EC2 Instance Connect, en el terminal haremos CTRL+C (bajarnos airflow), y luego volver a levantarlo

```bash
airflow standalone
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/1f40e55b-8fb0-448f-a063-4771caaecd71/Untitled.png)

Una vez reseteado el airflow, vemos como la modificacion en el archivo de configuración se hace efectiva, ya no hay más ejemplos de dags:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/8862ab70-34ed-427d-bb41-7487cbd0188f/Untitled.png)

Creamos una cuenta en RapidAPI: https://rapidapi.com/hub

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/c0baa348-ecfc-4b8c-a454-45a53d1569a7/Untitled.png)

Voy a utilizar los datos que Rapid API me ha proporcionado como parte del conjunto de datos de Zillow. Sin embargo, parece que los datos no es un dato real de Zillow, pero sirve con fines académicos.

Entonces tenemos que suscribirse a nuestra API en particular que vamos a utilizar

https://rapidapi.com/s.mahmoud97/api/zillow56

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/4e08b91f-8e5e-42f8-aef5-5e617c3d16ec/Untitled.png)

Ahora, para conectarnos a extraer datos, necesitamos esta urlAhora, para conectarnos a extraer datos, necesitamos esta url:
`https://zillow56.p.rapidapi.com/search`

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/175959e3-16d1-4f73-870b-41bb4295005c/Untitled.png)

Ahora vamos a crear nuestra primera tarea: Conectarnos a la API de Zillow Rapid y extraer los datos

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/204fe3cc-3a2b-4ee4-9405-e6f483206523/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/98ea2a68-4d19-47c0-be09-cd26ee6a29ae/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/4aa1417b-4dec-469a-949b-b7c254c7a4d7/Untitled.png)

OJO. 

```python
# Specify the output file path
now = datetime.now()
dt_now_string = now.strftime("%d%m%Y%H%M%S")
```

Guardamos, y vamos a ver si podemos ver este DAG en la interfaz de usuario de airflow, y sí después de unos minutos podemos verlo

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/18348f18-220c-409b-9d41-564a7b01b417/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/8a8e513b-181f-4072-8185-c96b4b00c921/Untitled.png)

Activemos nuestro DAG

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/84b42779-63f0-4453-add4-f353fb5b4a46/Untitled.png)

Y si vemos que falla, y para comprobar dónde está el error en Logs:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/c4051b2f-bc20-4c19-9fd2-3dacfec3c027/Untitled.png)

Necesitamos importar *requests*. Para probarlo de nuevo, lo que tenemos que hacer es *Clear task*, y lo volverá a correr.

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/ed587e9b-cad2-4ede-b7cf-73f0b2d4ec76/Untitled.png)

Y funciona:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/965fb4e4-4c4c-41c4-9df9-0cfffcd645a1/Untitled.png)

Y vemos el archivo resultante con la data *response_data_11032024142734.json*

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/c94a7fe5-e604-4273-837e-82feea24ec37/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/b9e797ce-706e-4caf-88eb-63e9868b18ec/Untitled.png)

Creo que esto sólo se puede utilizar para una ciudad a la vez. Así que hemos validar que nuestra primera tarea se ejecute correctamente. Ahora, ¿Cómo podemos mover estos datos a nuestro cubo S3 *zona de aterrizaje*?

Vamos a crear la segunda tarea que va a ser un operador bash y lo que va a hacer es que en el momento en que este archivo (*response_data_xxxxx.json*) se crea, queremos utilizar la segunda tarea para mover este archivo desde nuestra Instancia EC2 al bucket S3.

En primer lugar, tenemos que crear nuestro cubo:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/071a6c5a-6f23-4aaf-a74a-c15b10e0df3d/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/f5a4ad12-59bf-4af2-a3f7-994d94e9bce6/Untitled.png)

And the policy gonna be *AmazonS3FullAccess*. 

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d236f7dc-a482-4eda-b5c7-bebf8a3eede4/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/b23327b8-f0e3-4795-a511-a38f66d27da7/Untitled.png)

Ahora adjuntamos dicho rol a nuestra instancia:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/c6c39616-a8e6-454e-a496-d5eb40624d96/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/7abd3692-dc0f-4cb5-9660-5a576dc17b18/Untitled.png)

Ahora, no nos olvidemos de señalar las dependencias entre los tasks:

```python
# Dependencies
extract_zillow_data_var >> load_to_s3
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/3d782503-2293-4cf6-9c55-ca46f2090700/Untitled.png)

Entonces, ahora que trigguemos nuestro DAG, debemos ver nuestro json file inside our S3 bucket. 

**Nota.** Aquí experimenté un pequeño percance, pues me salía un error que me decía que no reconocía el comando bash. Luego, averiguando, como yo resetee el servidor de airflow, no estoy seguro pero había un error con la ubicación de aws. Por lo que para hallar su path corrí los siguientes comandos en el terminal:

```python
sudo apt-get update
sudo apt-get install awscli
aws --version
which aws
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/cf3f8b7b-a015-42fc-bca3-29899381f56e/Untitled.png)

Entonces, modifiqué el comando 

```python
bash_command = '/usr/bin/aws s3 mv {{ ti.xcom_pull("tsk_extract_zillow_data_var")[0]}} s3://restart-project-bucket/'
```

Y así logré ejecutar el DAG correctamente:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/61d63f62-3184-4ddb-b9a1-cc14a05bedaf/Untitled.png)

Y se almacenó correctamente en el bucket:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/8ef98797-eae5-47a8-a75c-2291f04178dc/Untitled.png)

Ahora, al cargar los datos de restart-project-bucket (*zona de aterrizaje*) en el bucket *zona intermedia*, se activará una función lambda que copiará y cargará esos mismos datos json de *zona de aterrizaje* a *zona intermedia*, antes de que podamos hacer la transformación. Así que esta función lambda tendrá una copia en bruto del bucket de *zona de aterrizaje*. Entonces, creemos nuestra función Lambda:

Y sobre los roles, necesitamos crear uno nuevo para que Lambda tenga acceso a S3:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/9dd5788a-c910-40ca-8765-45c7629f82f6/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/14457154-47d4-4503-90c5-6bd67179e1d3/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d4ef1ef5-ee20-40ec-8c62-e16fb77a4869/Untitled.png)

El AWSLambdaBasicExecutionRole nos permite acceder a los CloudWatch Logs con fines de monitoreo. Creamos la función Lambda:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/0ae7a2fa-f8c1-4cce-981b-5ce8fa9322d6/Untitled.png)

A continuación, tenemos que añadir un disparador. Cuando nuestros datos lleguen a esta Zona de Aterrizaje queremos que dispare esta Función Lambda (rawCopyJsonFile-lambdaFunction). Y que incluso es cada vez que se carga un archivo

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/03d587bf-9da6-46f6-ba91-1f4950a8317c/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a47f0448-e725-4938-9645-b78a6eb56846/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/8173bba2-8207-4bee-8c58-581e1dc5a171/Untitled.png)

Después de guardar (Deploy) nuestra función, necesitamos crear nuestro bucket de destino, donde irá la copia

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/46ab352e-9bc3-4565-9388-5844e9d77021/Untitled.png)

La copia es de *restart-project-bucket* a *restart-project-copy-raw-json-bucket*.

Así que ahora cuando vuelva a ejecutar airflow, se subirá un nuevo archivo .json al bucket de landing zone (restart-project-bucket), lo que disparará la función lambda que copiará estos datos en el bucket intermedio

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/23b2d9aa-fe70-44fe-a428-2377fc80b6f5/Untitled.png)

Y vemos que el nuevo archivo subido al Landing zone bucket se copia al *restart-project-copy-raw-json-bucket*

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/46589456-8623-4577-b8bd-a29203ab2321/Untitled.png)

Y ahora procedemos a crear la otra función lambda que se activará cuando detecte nuevos archivos en el bucket *restart-project-copy-raw-json-bucket*, nos permitirá hacer las transformaciones respectivas a la data:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/3a922220-82e6-4e39-9619-79e3027c5101/Untitled.png)

Entonces, creamos dicha función:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d280ff61-5016-49d3-9743-4776b6dc7bfc/Untitled.png)

Y configuramos nuestro disparador del que hemos hablado (Cubo intermedio):

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/52f2a663-360f-4d36-9a27-3561086bcc4b/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/34f3cffb-5f37-4d5f-bad8-7a2d62678121/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/0c35462a-655c-4414-9d87-04ee2831de31/Untitled.png)

Después de agregar el nuevo task y su respectiva dependenica, lo conveniente es reiniciar el servidor. **Nota.** Para esta tarea necesitamos dar acceso a Airflow a nuestro bucket S3

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2af1cf18-4cf8-4a50-a18f-29c742b9b74f/Untitled.png)

We create a connection, that will allow Airflow to connect to Amazon Web Services

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/f778913a-8c84-4491-88d3-2311027019c5/Untitled.png)

Bien, una vez establecida la conexión, procedemos a probar nuestro flujo con airflow, y obtenemos un error: Vemos que sí logra recuperar la conexión, sin embargo mientras espera que aparezca el archivo .csv, sobrepasa el límite de 60sec.

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/f8852e5c-e614-47b1-9084-1b3664c7e6f1/Untitled.png)

Y bueno el problema está en que la función lambda *transformation-json-to-csv-lambdFunction*, no se está ejecutando correctamente. Esto lo notamos en los ClaudWatch Logs. Donde vemos el siguiente mensaje:

```
[ERROR] Runtime.ImportModuleError: Unable to import module 'lambda_function': No module named 'pandas'
Traceback (most recent call last):
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/331546f5-bb2a-422a-ac7c-f4d3790c1010/Untitled.png)

Para solucionar este problema, lo que debemos hacer es añadir un Layer (*capa*) a la función

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/e66aa49a-6dfe-44ea-8c2d-1a644980f41b/Untitled.png)

Y vemos que el DAG se ejecutó correctamente:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d1901ac8-8965-469a-96bf-be03cb1dd9c5/Untitled.png)

Notamos que nuestro task *tsk_is_file_in_s3_available* fue un éxito debido a que logró identificar el archivo .csv en el bucket *restart-project-cleaned-zone-bucket*. Como resultado de la función que tenía como target dejar la data transformada en este bucket

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/719bc5bc-e18c-450a-9c2e-86ab04cac5df/Untitled.png)

la razón por la que necesitamos tener un sensor antes de añadir el *Operador Redshift*, porque si eres el operador Redshift aquí sin el sensor, eso significa que no tendrás la visibilidad al archivo en tu S3. Usted no sabe si está allí o no. 

Hasta ahora hemos trabajado en la extracción de datos de la ZillowAPI RapidAPI, cargamos eso en nuestro primer cubo S3 que llamamos la Zona de Aterrizaje, y eso desencadenó una Función Lambda que luego copia ese archivo json en otro cubo (Zona intermedia). Inmediatamente aterriza en este cubo, desencadena otra función lambda que hace algunas transformaciones, seleccionamos algunas columnas de los datos y luego convertimos los datos en CSV. Y luego lo cargamos en el cubo de la Zona Limpia. Ahora, lo que queremos hacer, queremos cargar los datos dentro de Redshift y luego usar PowerBI para visualizar algunos de esos datos. Hemos estado usando airflow para orquestar este proceso. Usamos S3KeySensor para detectar que el archivo .csv ya existe en el bucket Cleaned Zone

Así que ahora, vamos a crear nuestro cluster Redshift

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/b462ba58-c3c4-4448-8410-dbed1ba63298/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/dab1749c-63e5-4575-801d-71aa3c879f5e/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a8eff982-6a69-48b8-beb2-0cd152da82c6/Untitled.png)

Luego, vamos a nuestro query editor v2: Para conectarnos al data warehouse

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/b178356a-b368-49e9-b39e-15f76c80f626/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/9482e297-f8a7-4751-90e2-b4a4cca86274/Untitled.png)

Y vemos que aún no tiene registros

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/4bcf42b0-a8d3-4c79-ab1d-4364a2cb2705/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/ade8202b-5b8f-4085-a3f0-b07befd1afc5/Untitled.png)

**OJO.** Es necesario que nuestro servidor de Airflow, como le estamos dando conexión con Redshift, la instancia donde está desplegado este server debe tener permisos que le den acceso a Redshift

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/e875e73b-7a8b-4681-921e-1dcfc6e714f6/Untitled.png)

También debemos modificar las reglas de entrada (security group) de nuestro Redshift cluster:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/55eb1037-83cf-40c7-907d-7d74b743c77b/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/17a1268f-7a93-47d9-9db1-391f2d39b152/Untitled.png)

Vamos a correr nuestro DAG en la UI de airflow:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/afef7f0b-a053-4ac2-9a8e-a8be7366d673/Untitled.png)

Cuando lo ejecutamos debemos ser capaces de extraer los datos de la API a la zona de aterrizaje que desencadenan la función lambda y que copiará el archivo json en el cubo intermedio, que desencadena otra función lambda hacemos alguna transformación y también convertir a csv. Y que las cargas en la zona limpia cubo y luego tenemos un S3KeySensor que asegura que nuestros archivos está aquí. Si está allí, entonces se dispara el operador S3ToRedshift, que luego cargará el archivo .csv en Redshift

Fue un éxito

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d538470b-5592-440c-82dd-28967fc185c1/Untitled.png)

Asimismo, vemos que ya se cargó data al Redshift:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/d0e56877-f0e8-425f-bc4a-a208665846c4/Untitled.png)

Para reiniciar nuestro airflow (desplegado en nuestra instancia de EC2):

```bash
sudo pkill gunicorn
ps aux | grep gunicorn
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a2c73811-2ac4-4cba-b4a4-3cb126b16417/Untitled.png)

```bash
airflow standalone
```

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/0b516cce-7559-4308-ba5e-4b9d73b0af37/Untitled.png)

Si volvemos a ejecutar el DAG, los datos se añaden

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/a2a2fc9d-eaef-4a05-82a2-83037d382f45/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/2cb804b1-eb9c-4f6c-8a59-1a263ccd60f7/Untitled.png)

Podemos ver nuestro tamaño de almacenamiento

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/6647a7f8-013d-4681-9375-937e488b0db0/Untitled.png)

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

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/02f203a1-fcda-470a-ac7d-c44ae8c2ef9d/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/3e15e555-23ae-48e2-94a2-3f707fc38188/Untitled.png)

Y en PowerBI obtenemos los datos:

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/425e8df8-381c-4bac-b9e2-5e8e925bdc12/Untitled.png)

Server: [redshift-cluster-1.cfviphrlqe05.us-west-2.redshift.amazonaws.com:5439](http://redshift-cluster-1.cfviphrlqe05.us-west-2.redshift.amazonaws.com:5439/dev)

Database: dev

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/882fc4cc-5afc-4739-851b-4e17808fe861/Untitled.png)

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/7e95dc33-f9a9-4435-99a2-0d8991bf26e3/Untitled.png)

Y nos conectamos

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/1f5fabd1-5ee5-4826-bf8b-4804515f020b/de33b506-3852-49c2-ac7b-a67f49dc751a/Untitled.png)
