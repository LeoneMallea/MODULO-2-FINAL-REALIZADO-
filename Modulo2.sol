// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
/*
        Nombre: Leone Gabriel Mallea Mamani
        Github: https://github.com/LeoneMallea
        Email: leonemallea1@gmail.com
        Entrega Final Modulo 2
        VOTACION ELECTORAL 2025 CANDIDATOS A LA PRESIDENCIA 

*/



/// @title Sistema de Votación Descentralizado con Delegación de Voto
contract DecentralizedElection {
    // Dirección del administrador (quien despliega el contrato)
    address public admin;

    // Enum para las fases de la elección
    enum ElectionState { Registration, Voting, Ended }
    ElectionState public currentState;

    // Representa un candidato con nombre y número de votos
    struct Candidate {
        string name;
        uint voteCount;
    }

    // Representa un votante con datos de autorización, voto, delegación y peso
    struct Voter {
        bool authorized;      // ¿Puede votar?
        bool voted;           // ¿Ya votó?
        uint voteIndex;       // Índice del candidato al que votó
        address delegate;     // A quién delegó su voto
        uint weight;          // Peso de su voto (por defecto 1)
    }

    // Mapeo de dirección => Votante
    mapping(address => Voter) public voters;

    // Lista de candidatos
    Candidate[] public candidates;

    // Eventos para el frontend o notificaciones
    event VoterAuthorized(address voter);
    event CandidateAdded(string name);
    event VoteCasted(address voter, uint candidateIndex);
    event VoteDelegated(address from, address to);
    event ElectionStarted();
    event ElectionEnded();

    // Restricción para funciones solo puede ejecutar el admi
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo el admin puede ejecutar esto.");
        _;
    }

    // Restricción solo se ejecuten en un estado determinado
    modifier inState(ElectionState _state) {
        require(currentState == _state, "No disponible en esta fase.");
        _;
    }

  
    constructor() {
        admin = msg.sender;
        currentState = ElectionState.Registration;
    }

    ///  ESTA FUNCION (addCandidate) Agrega un candidato (solo en fase de registro)
    ///  Añadir candidatos a la eleccion 
    function addCandidate(string memory _name) public onlyAdmin inState(ElectionState.Registration) {
        candidates.push(Candidate(_name, 0));
        emit CandidateAdded(_name);
    }

    /// ESTA FUNCION (authorizeVoter) Autoriza a un votante (solo en fase de registro) 
    /// autoriza a una persona una direccion de ethereum para que vote
    function authorizeVoter(address _voter) public onlyAdmin inState(ElectionState.Registration) {
        voters[_voter].authorized = true;
        voters[_voter].weight = 1; // Cada votante vale 1 voto inicialmente
        emit VoterAuthorized(_voter);
    }

    /// ESTA FUNCION (startVoting) Comienza la votación (solo admin)
    /// cambia el estado de la eleccion de registro a votacion bloqueando candidatos y votantes nuevos 
    function startVoting() public onlyAdmin inState(ElectionState.Registration) {
        currentState = ElectionState.Voting;
        emit ElectionStarted();
    }

    ///  ESTA FUNCION (endElection) Finaliza la elección (solo admin)
    ///  FINALIZA LA ELECCION Y CAMBIA EL ESTADO A FINALIZADO
    function endElection() public onlyAdmin inState(ElectionState.Voting) {
        currentState = ElectionState.Ended;
        emit ElectionEnded();
    }

    /// ESTA FUNCION (vote) Emite un voto por un candidato (usando el peso del votante)
    /// CONSULTAR EL ESTADO DE UN VOTANTE SI ESTA AUTORIZADO SI YA VOTO A QUIEN DELEGO
    /// INGRESAR LA DIRECCION DEL VOTANTE
    function vote(uint _candidateIndex) public inState(ElectionState.Voting) {
        Voter storage sender = voters[msg.sender];

        require(sender.authorized, "No estas autorizado para votar.");
        require(!sender.voted, "Ya has votado.");
        require(_candidateIndex < candidates.length, "Candidato no valido.");

        sender.voted = true;
        sender.voteIndex = _candidateIndex;

        candidates[_candidateIndex].voteCount += sender.weight;

        emit VoteCasted(msg.sender, _candidateIndex);
    }

    /// ESTA FUNCION (delegateVote(address _to)) Permite a un votante delegar su voto a otro votante
    /// PERMITIR QUE UN VOTANTE DELEGUE SU VOTO A OTRA PERSONA
    /// QUE INGRESAR LA DIRECCION ETHEREUM DEL VOTANTE A QUIEN QUIERES DELAGAR EL VOTO 
    /// SOLO LOS VOTANTES AUTORIZADOS QUE NO HAYAN VOTADO PUEDEN DELEGAR
    function delegateVote(address _to) public inState(ElectionState.Voting) {
        Voter storage sender = voters[msg.sender];
        require(sender.authorized, "No estas autorizado.");
        require(!sender.voted, "Ya has votado.");
        require(_to != msg.sender, "No puedes delegarte a ti mismo.");

        // ESTO SIRVE PARA Detectar ciclos en la cadena de delegación
        address current = _to;
        while (voters[current].delegate != address(0)) {
            current = voters[current].delegate;
            require(current != msg.sender, "Delegacion en bucle detectada.");
        }

        sender.voted = true;
        sender.delegate = _to;

        Voter storage delegateTo = voters[_to];

        // Si el delegado ya votó, se transfiere el voto directamente
        if (delegateTo.voted) {
            candidates[delegateTo.voteIndex].voteCount += sender.weight;
        } else {
            // Si no ha votado, se incrementa su peso de voto
            delegateTo.weight += sender.weight;
        }

        emit VoteDelegated(msg.sender, _to);
    }

    /// ESTA FUNCION (getCandidates)Devuelve la lista de todos los candidatos
    /// DEVUELVE LA LISTA DE NOMBRE DE TODOS LOS CANDIDATOS 
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    /// ESTA FUNCION (getWinner) Devuelve el nombre del candidato ganador (solo cuando la elección ha terminado)
    /// MOSTRAR EL NOMBRE DEL CANDIDATO GANADOR EL TIENE MAS VOTOS 
    function getWinner() public view inState(ElectionState.Ended) returns (string memory winnerName) {
        uint highestVotes = 0;
        uint winnerIndex = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winnerIndex = i;
            }
        }

        return candidates[winnerIndex].name;
    }
}
