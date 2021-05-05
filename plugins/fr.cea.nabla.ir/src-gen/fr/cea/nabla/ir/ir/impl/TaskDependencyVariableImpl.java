/**
 */
package fr.cea.nabla.ir.ir.impl;

import fr.cea.nabla.ir.ir.IrPackage;
import fr.cea.nabla.ir.ir.TaskDependencyVariable;

import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EClass;

import org.eclipse.emf.ecore.impl.ENotificationImpl;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Task Dependency Variable</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskDependencyVariableImpl#getConnectivityName <em>Connectivity Name</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskDependencyVariableImpl#getIndexType <em>Index Type</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskDependencyVariableImpl#getIndex <em>Index</em>}</li>
 * </ul>
 *
 * @generated
 */
public class TaskDependencyVariableImpl extends VariableImpl implements TaskDependencyVariable {
	/**
	 * The default value of the '{@link #getConnectivityName() <em>Connectivity Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getConnectivityName()
	 * @generated
	 * @ordered
	 */
	protected static final String CONNECTIVITY_NAME_EDEFAULT = null;

	/**
	 * The cached value of the '{@link #getConnectivityName() <em>Connectivity Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getConnectivityName()
	 * @generated
	 * @ordered
	 */
	protected String connectivityName = CONNECTIVITY_NAME_EDEFAULT;

	/**
	 * The default value of the '{@link #getIndexType() <em>Index Type</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getIndexType()
	 * @generated
	 * @ordered
	 */
	protected static final String INDEX_TYPE_EDEFAULT = null;

	/**
	 * The cached value of the '{@link #getIndexType() <em>Index Type</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getIndexType()
	 * @generated
	 * @ordered
	 */
	protected String indexType = INDEX_TYPE_EDEFAULT;

	/**
	 * The default value of the '{@link #getIndex() <em>Index</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getIndex()
	 * @generated
	 * @ordered
	 */
	protected static final int INDEX_EDEFAULT = 0;

	/**
	 * The cached value of the '{@link #getIndex() <em>Index</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getIndex()
	 * @generated
	 * @ordered
	 */
	protected int index = INDEX_EDEFAULT;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected TaskDependencyVariableImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return IrPackage.Literals.TASK_DEPENDENCY_VARIABLE;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getConnectivityName() {
		return connectivityName;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setConnectivityName(String newConnectivityName) {
		String oldConnectivityName = connectivityName;
		connectivityName = newConnectivityName;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.TASK_DEPENDENCY_VARIABLE__CONNECTIVITY_NAME, oldConnectivityName, connectivityName));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getIndexType() {
		return indexType;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setIndexType(String newIndexType) {
		String oldIndexType = indexType;
		indexType = newIndexType;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX_TYPE, oldIndexType, indexType));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public int getIndex() {
		return index;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setIndex(int newIndex) {
		int oldIndex = index;
		index = newIndex;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX, oldIndex, index));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case IrPackage.TASK_DEPENDENCY_VARIABLE__CONNECTIVITY_NAME:
				return getConnectivityName();
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX_TYPE:
				return getIndexType();
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX:
				return getIndex();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case IrPackage.TASK_DEPENDENCY_VARIABLE__CONNECTIVITY_NAME:
				setConnectivityName((String)newValue);
				return;
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX_TYPE:
				setIndexType((String)newValue);
				return;
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX:
				setIndex((Integer)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case IrPackage.TASK_DEPENDENCY_VARIABLE__CONNECTIVITY_NAME:
				setConnectivityName(CONNECTIVITY_NAME_EDEFAULT);
				return;
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX_TYPE:
				setIndexType(INDEX_TYPE_EDEFAULT);
				return;
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX:
				setIndex(INDEX_EDEFAULT);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case IrPackage.TASK_DEPENDENCY_VARIABLE__CONNECTIVITY_NAME:
				return CONNECTIVITY_NAME_EDEFAULT == null ? connectivityName != null : !CONNECTIVITY_NAME_EDEFAULT.equals(connectivityName);
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX_TYPE:
				return INDEX_TYPE_EDEFAULT == null ? indexType != null : !INDEX_TYPE_EDEFAULT.equals(indexType);
			case IrPackage.TASK_DEPENDENCY_VARIABLE__INDEX:
				return index != INDEX_EDEFAULT;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String toString() {
		if (eIsProxy()) return super.toString();

		StringBuilder result = new StringBuilder(super.toString());
		result.append(" (connectivityName: ");
		result.append(connectivityName);
		result.append(", indexType: ");
		result.append(indexType);
		result.append(", index: ");
		result.append(index);
		result.append(')');
		return result.toString();
	}

} //TaskDependencyVariableImpl
