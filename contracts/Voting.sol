// SPDX-License-Identifier: MIT

//Versión del compilador. Incluye la 0.8.0 hasta 0.9.0, esta última no incluida.
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Voting {
    //Declaración de la estructura Vecino.
    struct Vecino {
        string nombre;
        uint256 edad;
        uint256 piso;
        string puerta;
    }

    //Declaración del array de tipo 'Vecino', con nombre de variable 'TodosVecinos'.
    Vecino[] private TodosVecinos;

    //Creación de la variable 'direccionPresidente' y la asociamos a la dirección que despliega el contrato.
    address direccionPresidente = msg.sender;
    //Declaración del modificador 'SoloPresidente'. Habilita solo al presidente a ejecutar aquellas funciones que dicho modificador.
    modifier SoloPresidente(address _direccionPresidente) {
        //Requiere que la direccion introducido por parametro sea igual al owner del contrato.
        require(
            _direccionPresidente == direccionPresidente,
            /*
                En caso de que no coincidan la dirección que ha desplegado el contrato y la dirección que 
                intenta ejecutar una función con el modificar, aparecerá este mensaje en consola.
            */
            "No tienes permisos para ejecutar esta funcion. Solo puede ejecutarla el actual Presidente"
        );
        _;
    }

    //Función para añadir todos los vecinos (voten o no) al array 'TodosVecinos'.
    //Para usos de aprendizaje y visualización, la funcion 'AddTodosVecinos' es 'public', aunque en realidad debería ser 'private'.
    function addTodosVecinos(
        string memory _nombre,
        uint256 _edad,
        uint256 _piso,
        string memory _puerta
    ) private SoloPresidente(msg.sender) {
        /* 
            En el futuro, añadir que no puede haber dos personas registradas en el mismo apartamente.
            ¿Como lo hacemos? Haciendo el hash de la combinación de piso y letra. Guardaremos este hash
            en un array. Antes de hacer el push al array 'TodosVecinos', comprobaremos si el hash de la 
            combinación de piso y letra ya existe. Mediante un 'if' podremos manejarlo.
         */
        TodosVecinos.push(Vecino(_nombre, _edad, _piso, _puerta));
    }

    //Función para saber cuantos índices hay dentro de 'TodosVecinos'
    /*
        Mi intención es pasar 'arrayIndices' como parametro de la función 'getTodosVecinos' para que 
        automoaticamente nos diese toda la información de los vecinos que tengamos disponible sin la 
        necesidad de introducirlo manualmente
    */
    // function lenTodosVecinos() public view returns (uint256) {
    //     return TodosVecinos.length;
    // }
    // uint[] private arrayIndices;
    // function createIndices() public returns (uint[] memory) {
    //     for (uint i=0; i<TodosVecinos.length; i++){
    //         arrayIndices.push(i);
    //     }
    //     return arrayIndices;
    // }

    //Función para ver todos los vecinos de la finca.
    function getTodosVecinos(uint256[] memory _indices)
        private
        view
        SoloPresidente(msg.sender)
        returns (
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            string[] memory
        )
    {
        string[] memory nombres = new string[](_indices.length);
        uint256[] memory edades = new uint256[](_indices.length);
        uint256[] memory pisos = new uint256[](_indices.length);
        string[] memory puertas = new string[](_indices.length);

        for (uint256 i = 0; i < _indices.length; i++) {
            Vecino storage vecino = TodosVecinos[_indices[i]];
            nombres[i] = vecino.nombre;
            edades[i] = vecino.edad;
            pisos[i] = vecino.piso;
            puertas[i] = vecino.puerta;
        }

        return (nombres, edades, pisos, puertas);
    }

    //------------

    //Para saber la información de la persona y saber si puede votar o no, creamos un mapping
    mapping(string => Vecino) MappingVecinos;

    function saveVecino(
        string memory _idVecino,
        string memory _nombre,
        uint256 _edad,
        uint256 _piso,
        string memory _puerta
    ) public SoloPresidente(msg.sender) {
        MappingVecinos[_idVecino] = Vecino(_nombre, _edad, _piso, _puerta);
    }

    function showMappingVecino(string memory _idVecino)
        public
        view
        SoloPresidente(msg.sender)
        returns (Vecino memory)
    {
        return MappingVecinos[_idVecino];
    }

    // Función para obtener el Hash de piso+letra
    function getHashNombrePuerta(string memory _idVecino)
        public
        view
        returns (bytes32)
    {
        string memory NombrePuerta = string(
            abi.encodePacked(
                MappingVecinos[_idVecino].nombre,
                MappingVecinos[_idVecino].puerta
            )
        );
        bytes32 hashNombrePuerta = keccak256(abi.encodePacked(NombrePuerta));
        return hashNombrePuerta;
    }

    bytes32[] ArrayHashNombrePuerta = [
        bytes32(
            0x3231d4a001fd0f6d66c3bd8dba50568f195ecd907783730730b95ac48163fe4e
        ),
        bytes32(
            0xf1132e860e0f1e29db0cfa827f2fae65d7483afcb0f95a8b6a7b6889f997bdf2
        )
    ];

    function mayorEdad(string memory _idVecino)
        public
        view
        returns (bool, string memory)
    {
        if (MappingVecinos[_idVecino].edad > 18) {
            /*
                Aqui dentro, despues de comprobar que es mayor de edad, debemos comprobar si el 'hashNombrePuerta'
                existe o no en un array previamente declarado y poblado con los posibles valores. En caso de que 
                no exista, seguir con el proceso y decir que puede votar y añadir su nombre a la lista de aptos
                para el voto. En caso de que el hash no exista en el array previamente declarado y poblado, o bien
                ya se haya registrado en la lista de votos, avisar. 
            */
            return (true, "Puede votar");
        } else {
            return (false, "Menor de edad, NO puede votar");
        }
    }

    bytes32[] ArrayVotantes;
    string[] ArrayCandidaturas;

    function ViveAqui(string memory _idVecino) public view returns (bool) {
        /*
            El primer hash de ArrayHashNombrePuerta corresponde a los valores [nombre --> Jaime, puerta --> A].
            El segundo corresponde a [nombre --> Ana, puerta --> B].
            Cualquier otra combinación debería devolver false. 
        */
        string memory NombrePuertaViveAqui = string(
            abi.encodePacked(
                MappingVecinos[_idVecino].nombre,
                MappingVecinos[_idVecino].puerta
            )
        );
        bytes32 hashNombrePuertaViveAqui = keccak256(
            abi.encodePacked(NombrePuertaViveAqui)
        );

        for (uint256 i = 0; i < ArrayHashNombrePuerta.length; i++) {
            if (ArrayHashNombrePuerta[i] == hashNombrePuertaViveAqui) {
                return true;
            }
        }

        return false;
    }

    //Funcion para presentarse como Presidente.
    function PresentarseComoPresidente(string memory _idVecino) public {
        ArrayCandidaturas.push(_idVecino);
    }

    //Funcion getter para ver quien se ha presentado
    function GetCandidaturas() public view returns (string[] memory) {
        return ArrayCandidaturas;
    }

    string[] VecinosQueHanVotado;

    //Funcion para votar a los que se han presentado. Cada dirección solo podrá votar una vez.
    function Votar(string memory _idVecino, string memory _idCandidato)
        public
        returns (
            bool,
            string memory,
            string memory
        )
    {
        //Añadimos el nombre del votante a un array y antes de votar miramos que no exista en ese array.
        for (uint256 i = 0; i < VecinosQueHanVotado.length; i++) {
            //Hash de el elemento i del array de vecinos que ya han ejercido su voto
            bytes32 hash_VecinosQueHanVotado = keccak256(
                abi.encodePacked(VecinosQueHanVotado[i])
            );
            //Hash del _idVecino que quiere votar
            bytes32 hash_Votante = keccak256(abi.encodePacked(_idVecino));

            //Si se encuentra una coincidencia, quiere decir que ese vecino ya ha votado. Se sale del bucle for.
            //Si no se encuentra coincidencia, pasamos al siguiente if.
            if (hash_VecinosQueHanVotado == hash_Votante) {
                return (false, "Ya has votado", _idCandidato);
            }
        }

        VecinosQueHanVotado.push(_idVecino);
        return (true, "Se ha contabilizado", _idCandidato);
        //Comprobamos que el _idCandidato se encuentre dentro del ArrayCandidaturas.
    }
}
