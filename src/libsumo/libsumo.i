%module libsumo

#ifdef SWIGPYTHON
%rename(edge) Edge;
%rename(inductionloop) InductionLoop;
%rename(junction) Junction;
%rename(lane) Lane;
%rename(lanearea) LaneArea;
%rename(multientryexit) MultiEntryExit;
%rename(person) Person;
%rename(poi) POI;
%rename(polygon) Polygon;
%rename(route) Route;
%rename(simulation) Simulation;
%rename(trafficlight) TrafficLight;
%rename(vehicle) Vehicle;
%rename(vehicletype) VehicleType;

// adding dummy init and close for easier traci -> libsumo transfer
%pythoncode %{
from traci import constants, exceptions

def isLibsumo():
    return True

def init(port):
    print("Warning! To make your code usable with traci and libsumo, please use traci.start instead of traci.init.")

def close():
    simulation.close()

def start(args):
    simulation.load(args[1:])

def simulationStep(step=0):
    simulation.step(step)
%}

%typemap(in) const std::vector<int>& (std::vector<int> vars) {
    const Py_ssize_t size = PySequence_Size($input);
    for (Py_ssize_t i = 0; i < size; i++) {
        vars.push_back(PyLong_AsLong(PySequence_GetItem($input, i)));
    }
    $1 = &vars;
}
%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) const std::vector<int>& {
    $1 = PySequence_Check($input) ? 1 : 0;
}


%typemap(out) std::map<int, std::shared_ptr<libsumo::TraCIResult> > {
    $result = PyDict_New();
    for (auto iter = $1.begin(); iter != $1.end(); ++iter) {
        const int theKey = iter->first;
        const libsumo::TraCIResult* const theVal = iter->second.get();
        const libsumo::TraCIDouble* const theDouble = dynamic_cast<const libsumo::TraCIDouble*>(theVal);
        if (theDouble != nullptr) {
            PyDict_SetItem($result, PyInt_FromLong(theKey), PyFloat_FromDouble(theDouble->value));
            continue;
        }
        const libsumo::TraCIInt* const theInt = dynamic_cast<const libsumo::TraCIInt*>(theVal);
        if (theInt != nullptr) {
            PyDict_SetItem($result, PyInt_FromLong(theKey), PyInt_FromLong(theInt->value));
            continue;
        }
        PyObject *value = SWIG_NewPointerObj(SWIG_as_voidptr(theVal), SWIGTYPE_p_libsumo__TraCIResult, 0);
        PyDict_SetItem($result, PyInt_FromLong(theKey), value);
    }
};

%typemap(out) libsumo::TraCIPosition {
    $result = PyTuple_Pack(2, PyFloat_FromDouble($1.x), PyFloat_FromDouble($1.y));
};

%typemap(out) libsumo::TraCIPositionVector {
    $result = PyList_New($1.size());
    int index = 0;
    for (auto iter = $1.begin(); iter != $1.end(); ++iter) {
        PyList_SetItem($result, index++, PyTuple_Pack(2, PyFloat_FromDouble(iter->x), PyFloat_FromDouble(iter->y)));
    }
};

%typemap(out) std::vector<libsumo::TraCIConnection> {
    $result = PyList_New($1.size());
    int index = 0;
    for (auto iter = $1.begin(); iter != $1.end(); ++iter) {
        PyList_SetItem($result, index++, PyTuple_Pack(8, PyBytes_FromString(iter->approachedLane.c_str()),
                                                         PyBool_FromLong(iter->hasPrio),
                                                         PyBool_FromLong(iter->isOpen),
                                                         PyBool_FromLong(iter->hasFoe),
                                                         PyBytes_FromString(iter->approachedInternal.c_str()),
                                                         PyBytes_FromString(iter->state.c_str()),
                                                         PyBytes_FromString(iter->direction.c_str()),
                                                         PyFloat_FromDouble(iter->length)));
    }
};

%exceptionclass libsumo::TraCIException;

#endif

%begin %{
#ifdef _MSC_VER
// ignore constant conditional expression warnings
#pragma warning(disable:4127)
#endif

#include <libsumo/TraCIDefs.h>
%}


// replacing vector instances of standard types, see https://stackoverflow.com/questions/8469138
%include "std_string.i"
%include "std_vector.i"
%template(StringVector) std::vector<std::string>;
%template(TraCIStageVector) std::vector<libsumo::TraCIStage>;

// exception handling
%include "exception.i"

// taken from here https://stackoverflow.com/questions/1394484/how-do-i-propagate-c-exceptions-to-python-in-a-swig-wrapper-library
%exception { 
    try {
        $action
    } catch (libsumo::TraCIException &e) {
#ifdef SWIGPYTHON
        PyObject *err = SWIG_NewPointerObj(new libsumo::TraCIException(e), SWIGTYPE_p_libsumo__TraCIException, 1);
        PyErr_SetObject(SWIG_Python_ExceptionType(SWIGTYPE_p_libsumo__TraCIException), err);
        SWIG_fail;
#else
        const std::string s = std::string("TraCI error: ") + e.what();
        SWIG_exception(SWIG_RuntimeError, s.c_str());
#endif
    } catch (std::runtime_error &e) {
        const std::string s = std::string("SUMO error: ") + e.what();
        SWIG_exception(SWIG_RuntimeError, s.c_str());
    } catch (...) {
        SWIG_exception(SWIG_RuntimeError, "unknown exception");
    }
}

// %feature("compactdefaultargs") libsumo::Simulation::findRoute;

// Add necessary symbols to generated header
%{
#include <libsumo/Edge.h>
#include <libsumo/InductionLoop.h>
#include <libsumo/Junction.h>
#include <libsumo/LaneArea.h>
#include <libsumo/Lane.h>
#include <libsumo/MultiEntryExit.h>
#include <libsumo/Person.h>
#include <libsumo/POI.h>
#include <libsumo/Polygon.h>
#include <libsumo/Route.h>
#include <libsumo/Simulation.h>
#include <libsumo/TrafficLight.h>
#include <libsumo/Vehicle.h>
#include <libsumo/VehicleType.h>
%}

// Process symbols in header
%include "TraCIDefs.h"
%include "Edge.h"
%include "InductionLoop.h"
%include "Junction.h"
%include "LaneArea.h"
%include "Lane.h"
%include "MultiEntryExit.h"
%include "Person.h"
%include "POI.h"
%include "Polygon.h"
%include "Route.h"
%include "Simulation.h"
%include "TrafficLight.h"
%include "Vehicle.h"
%include "VehicleType.h"

#ifdef SWIGPYTHON
%pythoncode %{
exceptions.TraCIException = TraCIException
%}
#endif
